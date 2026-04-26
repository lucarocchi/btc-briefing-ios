# BTC Briefing — iOS App + Trading Strategies

A terminal-style iOS app that displays a live BTC market briefing and monitors four systematic trading strategies on Kraken XBTUSD.

All data comes from **Kraken public APIs** — no authentication required.

## App

- Live BTC price, EMA200, Bollinger Bands, RSI, Fibonacci levels
- Terminal aesthetic: black background, monospaced font, line-by-line reveal
- Strategy signal monitor (S01–S04) — shows which setups are near trigger
- Local notifications: bias change, price near Fibonacci level
- Home screen widget (WidgetKit)
- Works offline: last briefing cached in UserDefaults

## Strategies

Four systematic strategies, each backtested on Kraken XBTUSD data from 2020 onward.

| # | Name | Timeframe | Direction | Trades | Win Rate | Total PnL |
|---|------|-----------|-----------|--------|----------|-----------|
| S01 | [BB Upper SHORT](docs/strategies/S01_bb_upper_short.md) | Daily | SHORT | 24 | **70.8%** | +9.02% |
| S02 | [EMA200 Proximity LONG](docs/strategies/S02_ema200_proximity_long.md) | Daily | LONG | 81 | **80.2%** | +56.38% |
| S04 | [EMA200 Weekly LONG](docs/strategies/S04_ema200_weekly_long.md) | Weekly | LONG | 17 | **82.4%** | +75.74% |

> PnL is cumulative, spot 1x (no leverage), after 0.52% round-trip fee. The live engine runs with 5x leverage on Kraken Futures.

## Disclaimer

This is a personal research project. Past backtest results do not guarantee future performance. Not financial advice.
