class MachineToken
  class Invalid < StandardError; end

  CLIENTS_VARIABLE = "MACHINE_CLIENTS"
  ALGORITHM = "HS256"
  MAX_LIFETIME = 5.minutes.to_i
  CLOCK_LEEWAY = 30 # seconds a board's clock may drift either way

  # The id of the client that signed the token; raises Invalid for anything else.
  def self.verify!(token, clients: configured_clients)
    issuer = JWT.decode(token, nil, false).first["iss"]
    secret = clients[issuer] or raise Invalid, "unknown client"

    claims, = JWT.decode(token, secret, true,
      algorithm: ALGORITHM, required_claims: %w[iss iat exp], verify_iat: { leeway: CLOCK_LEEWAY }, leeway: CLOCK_LEEWAY)
    lifetime = claims["exp"] - claims["iat"]
    raise Invalid, "token lives longer than #{MAX_LIFETIME}s" unless lifetime.between?(0, MAX_LIFETIME)

    issuer
  rescue JWT::DecodeError, TypeError, NoMethodError => error
    raise Invalid, error.message
  end

  def self.configured_clients
    ENV.fetch(CLIENTS_VARIABLE, "").split(",").filter_map do |entry|
      id, secret = entry.strip.split(":", 2)
      [ id, secret ] if id.present? && secret.present?
    end.to_h
  end
end
