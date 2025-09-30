import argparse, csv, json, os

def score(example, output):
    # Placeholder rubric - to be replaced with an actual LLM judge in the next step.
    return {"task_success": 0.7, "clarity": 0.8, "groundedness": 0.6}

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dataset", required=True)
    ap.add_argument("--out", default="eval/report.csv")
    args = ap.parse_args()
    rows = []
    with open(args.dataset) as f:
        for line in f:
            ex = json.loads(line)
            out = {"answer": ex.get("input", "")}
            s = score(ex, out)
            rows.append({**ex, **s})
    os.makedirs(os.path.dirname(args.out), exist_ok=True)
    with open(args.out, "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=rows[0].keys())
        w.writeheader(); w.writerows(rows)
    print(f"Saved {args.out}")

if __name__ == "__main__":
    main()
