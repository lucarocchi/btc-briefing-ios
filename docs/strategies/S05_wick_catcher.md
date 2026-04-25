# S05 — Wick Catcher LONG

## Descrizione

Strategia opportunistica a bassa frequenza. BTC produce occasionalmente **flash crash** — spike down del 5-10% in una singola candela oraria che si recuperano quasi completamente entro la stessa barra. Un limit buy permanente posizionato 5% sotto il prezzo di mercato intercetta questi momenti senza richiedere monitoraggio attivo.

Il trade si apre solo se il wick è ≥5% e la candela si chiude recuperando almeno il 3% — filtrando i veri crolli da quelli opportunistici.

## Logica

**Timeframe:** 1H (scansione continua)

**Filtri di entry:**
| Filtro | Valore |
|--------|--------|
| Wick down ≥ 5% rispetto all'open | Flash crash significativo |
| Close ≥ open × 0.97 | Recupero nella stessa barra |

**Entry:** Fill simulato a low × 1.001 (appena sopra il minimo)

**Exit:**
| Tipo | Livello |
|------|---------|
| Take Profit | +3% dall'entry |
| Stop Loss | −2% dall'entry |

## Backtest

**Periodo:** 2020-03-13 → 2025-10-10
**Fee:** 0.52% round-trip (taker Kraken)
**Dimensione:** spot 1x (senza leva)

### Statistiche

| Metrica | Valore |
|---------|--------|
| Totale trade | 37 |
| Win Rate | **94.6%** |
| Trade vincenti | 35 |
| Trade perdenti | 2 |
| TP hit | 35 |
| SL hit | 2 |
| Timeout | 0 |
| Avg win | +2.48% |
| Avg loss | -2.52% |
| **Total PnL (spot 1x)** | **+81.76%** |
| Max Drawdown | -2.52% |

### Trade per trade

| Data segnale | Entry | Exit | Risultato | PnL |
|---|---|---|---|---|
| 2020-03-13 | $4,591 | $4,499 | SL | -2.52% |
| 2020-03-13 | $3,917 | $4,035 | TP | +2.48% |
| 2020-03-16 | $4,484 | $4,619 | TP | +2.48% |
| 2020-04-30 | $8,834 | $9,099 | TP | +2.48% |
| 2020-05-15 | $9,234 | $9,511 | TP | +2.48% |
| 2020-08-05 | $11,122 | $11,456 | TP | +2.48% |
| 2020-11-26 | $17,158 | $17,673 | TP | +2.48% |
| 2020-11-30 | $16,677 | $17,177 | TP | +2.48% |
| 2021-01-04 | $27,948 | $28,786 | TP | +2.48% |
| 2021-01-10 | $34,910 | $35,957 | TP | +2.48% |
| 2021-01-10 | $35,040 | $36,091 | TP | +2.48% |
| 2021-01-11 | $33,538 | $34,545 | TP | +2.48% |
| 2021-01-11 | $30,919 | $31,846 | TP | +2.48% |
| 2021-02-11 | $45,545 | $46,912 | TP | +2.48% |
| 2021-02-22 | $45,047 | $46,398 | TP | +2.48% |
| 2021-02-23 | $45,045 | $46,396 | TP | +2.48% |
| 2021-03-16 | $52,552 | $54,129 | TP | +2.48% |
| 2021-04-23 | $48,496 | $49,951 | TP | +2.48% |
| 2021-05-13 | $45,045 | $46,396 | TP | +2.48% |
| 2021-05-19 | $35,535 | $34,825 | SL | -2.52% |
| 2021-05-19 | $29,830 | $30,725 | TP | +2.48% |
| 2021-05-19 | $34,254 | $35,282 | TP | +2.48% |
| 2021-09-07 | $42,042 | $43,303 | TP | +2.48% |
| 2021-10-21 | $54,154 | $55,779 | TP | +2.48% |
| 2021-10-28 | $58,006 | $59,746 | TP | +2.48% |
| 2022-09-21 | $18,590 | $19,148 | TP | +2.48% |
| 2022-11-08 | $17,293 | $17,812 | TP | +2.48% |
| 2022-11-11 | $16,366 | $16,857 | TP | +2.48% |
| 2023-06-30 | $29,405 | $30,287 | TP | +2.48% |
| 2023-12-04 | $39,515 | $40,701 | TP | +2.48% |
| 2023-12-11 | $40,039 | $41,240 | TP | +2.48% |
| 2024-01-03 | $39,541 | $40,727 | TP | +2.48% |
| 2024-02-28 | $56,056 | $57,738 | TP | +2.48% |
| 2024-08-05 | $49,160 | $50,635 | TP | +2.48% |
| 2024-12-05 | $91,892 | $94,649 | TP | +2.48% |
| 2025-02-26 | $80,606 | $83,024 | TP | +2.48% |
| 2025-10-10 | $100,100 | $103,103 | TP | +2.48% |

---
*Backtest eseguito su dati OHLCV Kraken XBTUSD. Non include slippage.*
