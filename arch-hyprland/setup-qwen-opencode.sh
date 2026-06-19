#!/usr/bin/env bash
set -uo pipefail

MODEL="${1:-qwen2.5-coder:7b}"
PROJECT_DIR="${2:-$(pwd)}"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
CONFIG_FILE="$CONFIG_DIR/opencode.json"
MODEL_ID="$MODEL"
NUM_CTX="${NUM_CTX:-16384}"
NUM_GPU="${NUM_GPU:-}"
OLLAMA_HOST="${OLLAMA_HOST:-127.0.0.1}"

# Ollama performance tuning
export OLLAMA_NUM_PARALLEL="${OLLAMA_NUM_PARALLEL:-1}"
export OLLAMA_MAX_LOADED_MODELS="${OLLAMA_MAX_LOADED_MODELS:-1}"
export OLLAMA_KEEP_ALIVE="${OLLAMA_KEEP_ALIVE:-5m}"
export OLLAMA_FLASH_ATTENTION=1

# Check Ollama version supports tool calling
OLLAMA_VER=$(ollama --version 2>/dev/null | grep -oP '\d+\.\d+\.\d+' || echo "0.0.0")
if [ "$(printf '%s\n' "0.5.0" "$OLLAMA_VER" | sort -V | head -1)" != "0.5.0" ]; then
  echo "WARNING: Ollama $OLLAMA_VER detected. Tool calling requires >= 0.5.0."
  echo "         Run: curl -fsSL https://ollama.com/install.sh | sh"
  echo ""
fi

# Check if model is already local
model_pulled=false
if ollama list 2>/dev/null | grep -q "^$MODEL\s"; then
  model_pulled=true
fi

if [ "$model_pulled" = false ]; then
  echo "==> Pulling model: $MODEL"
  if ! ollama pull "$MODEL" 2>&1; then
    echo "    Model '$MODEL' not found on Ollama."
    echo ""
    echo "Recommended models that support tools:"
    echo "  qwen2.5-coder:7b     - Best for coding + tools on 4GB VRAM"
    echo "  qwen2.5-coder:14b    - Stronger but slow without GPU"
    echo "  llama3.1:8b           - Good tool support, slightly larger"
    echo "  mistral:7b            - Decent tool calling"
    echo "  nemotron-mini:4b      - Lightweight, good tools"
    echo ""
    echo "Re-run: $0 <model-name>"
    exit 1
  fi
else
  echo "==> Model '$MODEL' already pulled."
fi

# Build GPU args for Ollama API
GPU_ARGS=""
if [ -n "$NUM_GPU" ]; then
  GPU_ARGS=", \"num_gpu\": $NUM_GPU"
fi

echo "==> Writing opencode config (context: ${NUM_CTX}, gpu: ${NUM_GPU:-auto})..."
mkdir -p "$CONFIG_DIR"
cat > "$CONFIG_FILE" <<JSON
{
  "\$schema": "https://opencode.ai/config.json",
  "model": "ollama/${MODEL_ID}",
  "provider": {
    "ollama": {
      "npm": "@ai-sdk/openai-compatible",
      "options": {
        "baseURL": "http://${OLLAMA_HOST}:11434/v1"
      },
      "models": {
        "${MODEL_ID}": {
          "tool_call": true,
          "limit": {
            "context": ${NUM_CTX},
            "output": 8192
          }
        }
      }
    }
  }
}
JSON

# Start Ollama if not already running
if curl -s http://${OLLAMA_HOST}:11434/api/tags &>/dev/null; then
  echo "==> Ollama already running."
else
  echo "==> Starting Ollama (background)..."
  ollama serve &>/tmp/ollama.log &
  sleep 3
  if ! curl -s http://${OLLAMA_HOST}:11434/api/tags &>/dev/null; then
    echo "    ERROR: Ollama failed to start. Check /tmp/ollama.log"
    exit 1
  fi
fi

echo "==> Launching opencode with model: ollama/$MODEL_ID"
echo "    Project: ${PROJECT_DIR}"
echo "    Context: ${NUM_CTX} | GPU layers: ${NUM_GPU:-auto} | Parallel: ${OLLAMA_NUM_PARALLEL}"
opencode "$PROJECT_DIR"
