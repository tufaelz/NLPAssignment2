#!/usr/bin/env bash
set -euo pipefail

LOG_DIR="logs/sft_experiment_filtered"
mkdir -p "${LOG_DIR}"
MODEL_ID="${MODEL_ID:-/home/mzt5720/models/Qwen2.5-Math-1.5B}"

EVAL_INTERVAL=32
EVAL_MAX_EXAMPLES=1500

declare -a RUNS=(
  "s16   --filter_correct --train_samples 16  --epochs 2 --max_steps 0 --eval_interval ${EVAL_INTERVAL} --eval_max_examples ${EVAL_MAX_EXAMPLES}"
  "s32   --filter_correct --train_samples 32  --epochs 2 --max_steps 0 --eval_interval ${EVAL_INTERVAL} --eval_max_examples ${EVAL_MAX_EXAMPLES}"
  "s64   --filter_correct --train_samples 64  --epochs 2 --max_steps 0 --eval_interval ${EVAL_INTERVAL} --eval_max_examples ${EVAL_MAX_EXAMPLES}"
  "s118  --filter_correct --train_samples 118 --epochs 2 --max_steps 0 --eval_interval ${EVAL_INTERVAL} --eval_max_examples ${EVAL_MAX_EXAMPLES}"
)

echo "=== Starting FILTERED SFT sweep at $(date) ==="
echo "Logs: ${LOG_DIR}"
echo

for item in "${RUNS[@]}"; do
  name=$(echo "$item" | awk '{print $1}')
  args=$(echo "$item" | cut -d' ' -f2-)

  ts=$(date +"%Y%m%d_%H%M%S")
  log_file="${LOG_DIR}/${ts}_${name}.log"

  echo "=== Run: ${name} @ $(date) ==="
  echo "CMD: uv run python scripts/sft_experiment.py ${args} --model_id ${MODEL_ID}"
  echo "LOG: ${log_file}"
  echo

  set +e
  {
    echo "===== BEGIN ${name} $(date) ====="
    echo "CMD: uv run python scripts/sft_experiment.py ${args} --model_id ${MODEL_ID}"
    echo
    uv run python scripts/sft_experiment.py ${args} --model_id "${MODEL_ID}"
    exit_code=$?
    echo
    echo "EXIT_CODE: ${exit_code}"
    echo "===== END ${name} $(date) ====="
    exit ${exit_code}
  } 2>&1 | tee "${log_file}"
  exit_code=${PIPESTATUS[0]}
  set -e

  if [[ "${exit_code}" -ne 0 ]]; then
    echo "!!! Run ${name} failed (exit ${exit_code}). Stop."
    echo "See: ${log_file}"
    exit "${exit_code}"
  fi

  echo "=== Run ${name} DONE @ $(date) ==="
  echo
done

echo "=== All FILTERED runs finished @ $(date) ==="
