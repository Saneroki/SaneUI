# Known Issues

Issues found in QA that could be looked at; each has a card on the task board. One section per module that has one.

## Tooltips

- When equipment is viewed in the Auction House, the comparison tooltip may flicker. (2026-10-21: comparisons are placed
  after their main tooltip is drawn; 2026-11-01: a tooltip refreshed within one frame no longer hides and shows its panel,
  the one remaining cause the code showed.)
