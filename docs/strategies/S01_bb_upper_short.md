# S01 — BB Upper SHORT (Daily)

## Descrizione

Strategia contrarian di breve termine. Quando BTC si avvicina alla **Bollinger Band superiore (daily)** con RSI in ipercomprato e un wick che supera la banda, la probabilità di un ritracciamento aumenta significativamente. La candela non deve essere ribassista (già in vendita) — si cerca il segnale di esaurimento del trend prima che il mercato inverta.

## Logica

**Timeframe:** Daily (1D)

**Filtri di entry (tutti richiesti):**
| Filtro | Valore |
|--------|--------|
| Close ≤ BB upper | Chiusura dentro o sotto la banda |
| Close ≥ BB upper × 0.97 | Proximity 3% — non troppo lontano |
| RSI(14) > 70 | Ipercomprato confermato |
| High > BB upper | Wick rejection sopra la banda |
| Candle type ≠ bear | No candele già ribassiste |

**Parametri BB:** periodo 20, deviazione standard 2.0

**Entry:** Market SHORT all'open della candela successiva

**Exit:**
| Tipo | Livello |
|------|---------|
| Take Profit | −2.5% dall'entry |
| Stop Loss | +3.0% dall'entry |

## Backtest

**Periodo:** 2020-07-31 → 2025-10-06
**Fee:** 0.52% round-trip (taker Kraken)
**Dimensione:** spot 1x (senza leva)

### Statistiche

| Metrica | Valore |
|---------|--------|
| Totale trade | 24 |
| Win Rate | **70.8%** |
| Trade vincenti | 17 |
| Trade perdenti | 7 |
| TP hit | 17 |
| SL hit | 7 |
| Timeout (>30 giorni) | 0 |
| Avg win | +1.98% |
| Avg loss | -3.52% |
| **Total PnL (spot 1x)** | **+9.02%** |
| Max Drawdown | -13.64% |

### Trade per trade

| Data segnale | Entry | Exit | Risultato | PnL |
|---|---|---|---|---|
| 2020-07-31 | $11,356 | $11,697 | SL | -3.52% |
| 2020-10-20 | $11,927 | $12,285 | SL | -3.52% |
| 2020-10-27 | $13,649 | $13,308 | TP | +1.98% |
| 2020-11-18 | $17,800 | $18,334 | SL | -3.52% |
| 2020-11-19 | $17,827 | $18,362 | SL | -3.52% |
| 2020-11-21 | $18,709 | $18,241 | TP | +1.98% |
| 2020-12-26 | $26,442 | $27,235 | SL | -3.52% |
| 2021-01-05 | $34,050 | $35,071 | SL | -3.52% |
| 2021-01-09 | $40,257 | $39,250 | TP | +1.98% |
| 2021-10-20 | $66,036 | $64,385 | TP | +1.98% |
| 2022-03-29 | $47,440 | $46,254 | TP | +1.98% |
| 2023-01-17 | $21,149 | $20,620 | TP | +1.98% |
| 2023-01-21 | $22,786 | $23,469 | SL | -3.52% |
| 2023-04-14 | $30,493 | $29,731 | TP | +1.98% |
| 2023-06-24 | $30,542 | $29,779 | TP | +1.98% |
| 2023-06-25 | $30,447 | $29,686 | TP | +1.98% |
| 2023-11-09 | $36,702 | $35,785 | TP | +1.98% |
| 2023-11-10 | $37,312 | $36,379 | TP | +1.98% |
| 2023-12-08 | $44,180 | $43,075 | TP | +1.98% |
| 2024-02-15 | $51,947 | $50,648 | TP | +1.98% |
| 2024-10-30 | $72,331 | $70,523 | TP | +1.98% |
| 2025-05-21 | $109,675 | $106,933 | TP | +1.98% |
| 2025-10-05 | $123,542 | $120,454 | TP | +1.98% |
| 2025-10-06 | $124,766 | $121,647 | TP | +1.98% |

---
*Backtest eseguito su dati OHLCV Kraken XBTUSD. Non include slippage.*
