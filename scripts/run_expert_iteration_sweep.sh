#!/usr/bin/env bash
set -euo pipefail

# ==========================
# Logging
# ==========================
LOG_DIR="logs/expert_iteration"
mkdir -p "${LOG_DIR}"

# ==========================
# Common defaults
# ==========================
N_EI_STEPS=5
EVAL_MAX_EXAMPLES=1500
SAMPLING_MAX_TOKENS=512
SAMPLING_MIN_TOKENS=4
SEED=0


# ==========================
# Sweep list
# Format:
#   "<name>  <args...>"
# ==========================
declare -a RUNS=(
  "G2_E2_D64   --G 2 --epochs 2 --D_i 64"
  "G3_E2_D96   --G 3 --epochs 2 --D_i 96"
  "G4_E2_D128  --G 4 --epochs 2 --D_i 128"
)

echo "=== Starting Expert Iteration sweep at $(date) ==="
echo "Logs will be saved to: ${LOG_DIR}"
echo "n_ei_steps=${N_EI_STEPS}, eval_max_examples=${EVAL_MAX_EXAMPLES}, sampling_max_tokens=${SAMPLING_MAX_TOKENS}"
echo

for item in "${RUNS[@]}"; do
  name=$(echo "$item" | awk '{print $1}')
  args=$(echo "$item" | cut -d' ' -f2-)

  ts=$(date +"%Y%m%d_%H%M%S")
  log_file="${LOG_DIR}/${ts}_${name}.log"

  echo "=== Run: ${name} @ $(date) ==="
  echo "Command: uv run python scripts/expert_iteration_experiment.py ${args} ..."
  echo "Log: ${log_file}"
  echo

  set +e
  {
    echo "===== BEGIN ${name} $(date) ====="
    echo "CMD: uv run python scripts/expert_iteration_experiment.py ${args} \\"
    echo "  --n_ei_steps ${N_EI_STEPS} \\"
    echo "  --eval_max_examples ${EVAL_MAX_EXAMPLES} \\"
    echo "  --sampling_max_tokens ${SAMPLING_MAX_TOKENS} \\"
    echo "  --sampling_min_tokens ${SAMPLING_MIN_TOKENS} \\"
    echo "  --seed ${SEED} \\"
    echo

    uv run python scripts/expert_iteration_experiment.py \
      ${args} \
      --n_ei_steps "${N_EI_STEPS}" \
      --eval_max_examples "${EVAL_MAX_EXAMPLES}" \
      --sampling_max_tokens "${SAMPLING_MAX_TOKENS}" \
      --sampling_min_tokens "${SAMPLING_MIN_TOKENS}" \
      --micro_batch_size 1 \
      --grad_acc_steps 1 \
      --seed "${SEED}"
    exit_code=$?
    echo
    echo "EXIT_CODE: ${exit_code}"
    echo "===== END ${name} $(date) ====="
    exit ${exit_code}
  } 2>&1 | tee "${log_file}"
  exit_code=${PIPESTATUS[0]}
  set -e

  if [[ "${exit_code}" -ne 0 ]]; then
    echo
    echo "!!! Run ${name} failed with exit code ${exit_code}. Stopping sweep."
    echo "See log: ${log_file}"
    exit "${exit_code}"
  fi

  echo
  echo "=== Run ${name} finished successfully @ $(date) ==="
  echo
done

echo "=== All Expert Iteration runs completed at $(date) ==="