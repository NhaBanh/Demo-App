# ADR 0004: Build the To Buy Screen from a Catalog Model Enriched with Local Wishlist Snapshots

## Context

The `To Buy` module combines two different kinds of information:

- remote catalog data returned by `BuyRepository`
- user-specific local wishlist state stored in `SwiftData`

The first implementation treated wishlist as a simple boolean toggle on `BuyItem`. That was convenient for rendering, but it mixed catalog data with local user state. The wishlist feature later grew to support:

- quantity instead of a boolean flag
- persistence of a lightweight item snapshot
- a dedicated wishlist screen with availability-aware status

That combination created two modeling pressures:

- `BuyItem` should stay a clean catalog/domain entity
- the app still needs to show local wishlist state without making the catalog entity carry user-owned persistence concerns

As the flow evolved, the catalog and wishlist responsibilities also became clearer:

- the catalog screen should remain focused on the current remote result set
- the wishlist screen should remain focused on saved local items, including later snapshot refresh
- the remote API should remain the source of truth for current catalog visibility and availability

## Decision

Keep `BuyItem` as the pure catalog entity returned by `BuyRepository`.

Represent local wishlist persistence separately through `WishlistRepository`, which stores:

- wishlist quantity
- saved item snapshots used by the wishlist flow

Introduce a merged `BuyCatalogListItem` model for the screen-facing result of `LoadBuyCatalogUseCase`.

The responsibility split is:

- `BuyRepository`: fetch remote catalog items as `BuyItem`
- `WishlistRepository`: persist wishlist quantity and saved snapshots, and refresh those snapshots when needed
- `LoadBuyCatalogUseCase`: merge the current remote catalog page with local wishlist quantity for matching item IDs only
- `LoadWishlistUseCase`: return local wishlist items first, then coordinate background snapshot refresh for the wishlist screen
- `BuyCatalogViewModel` and `BuyCatalogView`: render the remote catalog result enriched with local wishlist quantity
- `WishlistViewModel` and `WishlistView`: manage saved local wishlist items as a separate feature flow

This means the `To Buy` screen is intentionally not a raw API list and not a raw wishlist list. It is a derived catalog view assembled from the remote result plus local quantity overlays for the same item IDs. The wishlist screen is the place where saved local items continue to exist independently from the current catalog page.

## Consequences

This keeps the core `BuyItem` model cleaner and makes it easier to reuse the catalog entity outside the wishlist-driven UI. It also keeps the current catalog authoritative for what is shown in `To Buy`, while still preserving richer local wishlist behavior in the separate wishlist flow.

The tradeoff is one extra mapping layer and one extra domain type (`BuyCatalogListItem`), plus a second read path for the dedicated wishlist screen. That is acceptable here because it keeps catalog concerns, local wishlist persistence, and snapshot refresh responsibilities explicit instead of collapsing them into one overloaded model or one overloaded screen.
