# S04 — EMA200 Weekly LONG

## Descrizione

La strategia più rara ma con il risk/reward più alto. Su timeframe **weekly**, la EMA200 è un supporto storico cruciale — ogni volta che BTC l'ha toccata in un regime bullish ha rappresentato un'opportunità di acquisto eccezionale. Il filtro sulla candela precedente (eravamo sopra EMA200) esclude i casi in cui BTC è già in downtrend strutturale.

Alta discrezionalità, pochi trade, grandi movimenti.

## Logica

**Timeframe:** Weekly (aggregato da daily)

**Filtri di entry (tutti richiesti):**
| Filtro | Valore |
|--------|--------|
| Low weekly ≤ EMA200 weekly | La candela tocca la media |
| Close settimana precedente > EMA200 | Eravamo sopra — non è un breakdown |
| Candle type ≠ bear / marubozu_bear | No candele fortemente ribassiste |

**Entry:** Market LONG al lunedì successivo (apertura settimana)

**Exit:**
| Tipo | Livello |
|------|---------|
| Take Profit | +8% dall'entry |
| Stop Loss | −10% dall'entry |

## Backtest

**Periodo:** 2020-02-11 → 2026-04-07
**Fee:** 0.52% round-trip (taker Kraken)
**Dimensione:** spot 1x (senza leva)

### Statistiche

| Metrica | Valore |
|---------|--------|
| Totale trade | 13 |
| Win Rate | **61.5%** |
| Trade vincenti | 8 |
| Trade perdenti | 5 |
| TP hit | 7 |
| SL hit | 5 |
| Timeout (>90 giorni) | 1 |
| Avg win | +6.99% |
| Avg loss | -10.52% |
| **Total PnL (spot 1x)** | **+3.29%** |
| Max Drawdown | -16.60% |

### Trade per trade

| Data segnale | Entry | Exit | Risultato | PnL |
|---|---|---|---|---|
| 2020-02-11 | $9,702 | $8,732 | SL | -10.52% |
| 2020-02-18 | $9,662 | $8,696 | SL | -10.52% |
| 2020-06-02 | $9,782 | $10,565 | TP | +7.48% |
| 2020-06-16 | $9,694 | $10,470 | TP | +7.48% |
| 2022-05-10 | $29,826 | $32,212 | TP | +7.48% |
| 2022-05-24 | $31,710 | $28,539 | SL | -10.52% |
| 2023-05-09 | $27,166 | $29,339 | TP | +7.48% |
| 2023-05-23 | $27,741 | $24,967 | SL | -10.52% |
| 2023-09-26 | $27,501 | $29,701 | TP | +7.48% |
| 2026-02-03 | $70,104 | $63,094 | SL | -10.52% |
| 2026-02-10 | $68,860 | $74,369 | TP | +7.48% |
| 2026-03-03 | $68,447 | $73,923 | TP | +7.48% |
| 2026-04-07 | $74,441 | $77,455 | TIMEOUT | +3.53% |

---
*Backtest eseguito su dati OHLCV Kraken XBTUSD. Non include slippage.*
