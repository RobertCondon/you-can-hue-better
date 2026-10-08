# Design previews

Self-contained preview pages of this app's visual language, built from `app/assets/stylesheets/application.css`
(copied here as `_app.css`). Each page starts with an `@dsCard` marker so a claude.ai/design design-system
project can show it as a card. Push them with `/design-sync` from this folder.

Regenerate after changing the stylesheet: `cp app/assets/stylesheets/application.css design/_app.css` and
re-run the generator in the commit that made these (the pages inline the CSS).

- foundations/colors.html, foundations/type.html
- components/nav.html, chips.html, room.html, panel.html, scene-card.html, floor.html
