# Design previews

Self-contained preview pages of this app's visual language. Each page starts with an `@dsCard`
marker so a claude.ai/design design-system project can show it as a card. Push them with
`/design-sync` from this folder.

`_app.css` is the app's stylesheets joined in load order. Rebuild it after changing them:

    bin/rails design:stylesheet

The pages inline their CSS, so a page only picks up a stylesheet change when it is regenerated.

- foundations/colors.html, foundations/type.html
- components/nav.html, chips.html, room.html, panel.html, scene-card.html, floor.html
