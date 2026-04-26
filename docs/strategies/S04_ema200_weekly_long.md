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

**Entry:** Market LONG al lunedì successivo (apertura settimana)

**Exit:**
| Tipo | Livello |
|------|---------|
| Take Profit | +8% dall'entry |
| Stop Loss | −10% dall'entry |
| Timeout | close dopo 40 giorni |

## Backtest

**Periodo:** 2020-03-16 → 2026-04-13
**Fee:** 0.52% round-trip (taker Kraken)
**Dimensione:** spot 1x (senza leva)

### Statistiche

| Metrica | Valore |
|---------|--------|
| Totale trade | 17 |
| Win Rate | **82.4%** |
| Trade vincenti | 14 |
| Trade perdenti | 3 |
| TP hit | 13 |
| SL hit | 2 |
| Timeout | 2 |
| Avg win | +6.86% |
| Avg loss | -7.72% |
| **Total PnL (spot 1x)** | **+75.74%** |

### Trade per trade

| Data segnale | Entry | Exit | Tipo candela | Risultato | PnL |
|---|---|---|---|---|---|
| 2020-03-16 | $5,821 | $6,286 | bear | TP | +7.48% |
| 2020-03-30 | $6,779 | $7,321 | doji_neutral | TP | +7.48% |
| 2022-05-16 | $30,264 | $27,238 | hammer_bull | SL | -10.52% |
| 2022-06-13 | $20,550 | $22,194 | marubozu_bear | TP | +7.48% |
| 2023-06-19 | $30,447 | $29,047 | bull | TIMEOUT | -5.12% |
| 2023-08-21 | $26,087 | $28,174 | marubozu_bear | TP | +7.48% |
| 2023-08-28 | $25,969 | $28,047 | doji_neutral | TP | +7.48% |
| 2023-09-04 | $25,830 | $27,896 | shooting_star_bear | TP | +7.48% |
| 2023-09-11 | $26,540 | $28,663 | bear | TP | +7.48% |
| 2026-02-09 | $68,780 | $74,282 | neutral | TP | +7.48% |
| 2026-02-16 | $67,612 | $73,021 | hammer_bull | TP | +7.48% |
| 2026-02-23 | $65,764 | $71,025 | marubozu_bear | TP | +7.48% |
| 2026-03-09 | $72,827 | $65,544 | shooting_star_bear | SL | -10.52% |
| 2026-03-16 | $67,857 | $73,286 | marubozu_bull | TP | +7.48% |
| 2026-03-23 | $65,950 | $71,226 | bear | TP | +7.48% |
| 2026-03-30 | $68,984 | $74,503 | bear | TP | +7.48% |
| 2026-04-13 | $73,828 | $77,648 | marubozu_bull | TIMEOUT | +4.66% |

---
*Backtest eseguito su dati OHLCV Kraken XBTUSD. Non include slippage.*
