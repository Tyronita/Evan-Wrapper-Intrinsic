# AIC Competition — Claude Code Init

## Project Identity
**AI for Industry Challenge (AIC)** — Hosted by Intrinsic AI (Alphabet/Google).
Team codebase: `Project-Automaton`. Primary contributor: Liberty (Evan) + Shi Hao Ng (Imperial College London).

## Competition Summary
- **Task:** Autonomous cable/connector insertion using a UR5e arm in a Gazebo simulation
- **Qualifier deadline:** ~May 27 2026 (internal freeze) / June 30 2026 (public outer bound)
- **Full challenge:** March 2026 – September 2026
- **Evaluator:** Gazebo (ROS 2 Kilted) on NVIDIA L4 (24 GB VRAM cloud instance)

## Scoring Tiers (use scoring.md as truth)
- **Tier 1:** Approach (cable moved toward target region) — max 6 pts
- **Tier 2:** Alignment (plug oriented correctly at port entrance) — max 12 pts
- **Tier 3:** Insertion (plug physically seated) — max 6 pts + **75 pts for full insertion**
- **Penalties:** >20N wrist force, off-limit contact, excessive duration

## Three-Lane Simulator Strategy
| Lane | Tool | Role |
|------|------|------|
| Truth | Gazebo (Kilted) | All scoring decisions, final eval |
| Controller | MuJoCo mirror | Fast gain sweeps, impedance tuning |
| Learning | Isaac Lab (AIC-Task-v0) | Teleop demos, RL training, dataset gen |

## Core Policy Architecture
- **CheatCode.py** — Oracle (uses ground truth TF; training/debug only)
- **RunACT.py** — Student (ACT policy trained on Oracle demonstrations)
- **GentleGiant / SpeedDemon / WallToucher / WallPresser** — official baselines
- Policy receives: 3x wrist RGB images, CameraInfos, joint states, wrist wrench, controller state @ 20 Hz

## Winning Strategy (Fundamental)
1. Run CheatCode at scale → generate 10k+ perfect insertion demos
2. Train ACT/Diffusion Policy student on those demos (Teacher-Student Distillation)
3. State machine wrapper: high stiffness (approach) → low stiffness (insertion)
4. Non-GT perception: keypoint detectors for plug-tip + target port
5. MuJoCo gain sweeps → bring best gains back to Gazebo
6. Everything fits inside NVIDIA L4 (24 GB) for cloud eval

## Key Hardware
- Local: NVIDIA RTX 5090 (Windows workstation)
- Cloud training: Vast.ai / Tensordock (RTX 6000 Pro, L40)
- Cloud eval: NVIDIA L4 (24 GB) — always keep inference path within this budget

## PyTorch Override for RTX 5090
```toml
[pypi-options.dependency-overrides]
torch = ">=2.7.1"
torchvision = ">=0.22.1"
```

## Important Docs (GitHub intrinsic-dev/aic)
- `docs/qualification_phase.md` — task spec
- `docs/scoring.md` — authoritative scoring (NOT scoring_tests.md)
- `docs/policy.md` — observation interface
- `docs/getting_started.md` — ROS 2 Kilted setup
- `aic_utils/aic_mujoco/README.md` — MuJoCo mirror
- `aic_utils/aic_isaac/README.md` — Isaac Lab lane

---

## Competition Format (Detailed)

**AI for Industry Challenge** by Intrinsic AI (Alphabet). Single task: insert fiber-optic connectors (LC/SC/SFP) into randomized task board ports using a UR5e arm + 3 wrist RGB cameras + F/T sensor. No depth. No GT at eval time.

- Qualifier: internal freeze ~**May 27**, outer bound **June 30 2026**
- Evaluated in **Gazebo / ROS 2 Kilted** on an **NVIDIA L4 (24 GB)**

### Scoring (use `scoring.md` as truth)

| Achievement | Points |
|-------------|--------|
| Approach (Tier 1) | 6 |
| Alignment (Tier 2) | 12 |
| Partial insertion (Tier 3) | 6 |
| **Full insertion** | **75** |

Penalties for >20N force, off-limit contact, and excessive duration.

### Competition Aims

1. Prove learned policies can handle **~1mm precision contact-rich manipulation** without GT
2. Force-aware, safe compliance (industrial relevance)
3. Sim-to-real generalization under randomized geometry
4. Multi-modal perception: RGB + F/T, no depth

### How Novelty Is Explored

- **Perception:** Keypoint detectors for plug-tip + port, multi-view depth cues from 3 RGB cameras, cable state estimation (HANDLOOM)
- **Control:** Variable impedance — stiff approach, compliant insertion; force-guided phase switching
- **Learning:** Teacher-Student Distillation, Asymmetric Actor-Critic (LUPI), hybrid analytic+learned
- **Architecture:** ACT (action chunking), Diffusion Policy, state-machine wrappers

### How to Win — Fundamentally

```
CheatCode GT oracle (Gazebo, 10k+ perfect demos)
  → ACT/Diffusion student trains on RGB → action pairs
  → State machine: stiff (approach) → compliant (insertion)
  → Non-GT perception for plug-tip + port localization
  → All decisions validated in Gazebo → scoring.yaml
  → Policy fits NVIDIA L4 (24 GB) for cloud eval
```

**One-line:** Train a compliant force-aware student policy via Teacher-Student Distillation, with a phase-switching impedance wrapper, validated entirely in Gazebo.
