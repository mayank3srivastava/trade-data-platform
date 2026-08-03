#!/usr/bin/env python3
"""Generate realistic trade events, including controlled invalid scenarios."""
from __future__ import annotations

import argparse
import csv
import random
import uuid
from datetime import date, datetime, timedelta, timezone
from decimal import Decimal
from pathlib import Path

INSTRUMENTS = ["EURUSD", "GBPUSD", "USDJPY", "AAPL", "MSFT", "US10Y"]
COUNTERPARTIES = ["CP_BANK_A", "CP_BANK_B", "CP_FUND_A", "CP_CORP_A"]
CURRENCIES = ["USD", "EUR", "GBP", "JPY"]


def utc_now() -> datetime:
    return datetime.now(timezone.utc).replace(microsecond=0)


def generate_rows(count: int, invalid_ratio: float, seed: int | None) -> list[dict[str, object]]:
    rng = random.Random(seed)
    now = utc_now()
    rows: list[dict[str, object]] = []
    known_trade_ids: list[str] = []

    for index in range(count):
        scenario = rng.random()
        trade_id = f"TRD-{uuid.uuid4().hex[:12].upper()}"
        version = 1
        maturity = date.today() + timedelta(days=rng.randint(1, 365))

        # Generate lower-version and same-version events for existing trade IDs.
        if known_trade_ids and scenario < invalid_ratio / 2:
            trade_id = rng.choice(known_trade_ids)
            version = 0  # intentionally lower than current version
        elif known_trade_ids and scenario < invalid_ratio:
            trade_id = rng.choice(known_trade_ids)
            version = 1  # same version; should replace current payload
        elif scenario < invalid_ratio * 1.5:
            maturity = date.today() - timedelta(days=rng.randint(1, 30))

        if trade_id not in known_trade_ids and version >= 1:
            known_trade_ids.append(trade_id)

        quantity = rng.randint(1, 10_000)
        price = Decimal(str(round(rng.uniform(10, 2500), 4)))
        rows.append(
            {
                "event_id": str(uuid.uuid4()),
                "trade_id": trade_id,
                "version": version,
                "counterparty_id": rng.choice(COUNTERPARTIES),
                "instrument_id": rng.choice(INSTRUMENTS),
                "trade_date": date.today().isoformat(),
                "maturity_date": maturity.isoformat(),
                "quantity": quantity,
                "price": str(price),
                "currency": rng.choice(CURRENCIES),
                "side": rng.choice(["BUY", "SELL"]),
                "source_system": "MOCK_TRADING_ENGINE",
                "event_ts": (now + timedelta(milliseconds=index)).isoformat(),
            }
        )
    return rows


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--count", type=int, default=1000)
    parser.add_argument("--invalid-ratio", type=float, default=0.10)
    parser.add_argument("--seed", type=int)
    parser.add_argument("--output", default="sample_data/trades.csv")
    args = parser.parse_args()

    if args.count <= 0:
        raise ValueError("--count must be positive")
    if not 0 <= args.invalid_ratio <= 0.5:
        raise ValueError("--invalid-ratio must be between 0 and 0.5")

    rows = generate_rows(args.count, args.invalid_ratio, args.seed)
    output = Path(args.output)
    output.parent.mkdir(parents=True, exist_ok=True)
    with output.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=rows[0].keys())
        writer.writeheader()
        writer.writerows(rows)
    print(f"Generated {len(rows)} trades at {output}")


if __name__ == "__main__":
    main()
