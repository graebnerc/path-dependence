# Modelling path dependence using Polya urn models

## Introduction

This code recreates the figures of Gräbner-Radkowitsch & Kapeller ([forthcoming](https://www.uni-due.de/imperia/md/content/soziooekonomie/ifsowp36_graebner-radkowitschkapeller_2024.pdf)).

To run all simulations simply run the script `polya_urn_simulations.R`.
This will run the cases as described in the main paper and creates the figures in the subdirectory `figures`.

## Description of the cases

All three cases follow the general structure of a Polya urn process, starting with an urn containing one ball of each color (orange and purple). In each round $t$, one ball is drawn randomly, returned to the urn, and additional balls are added according to the specific replacement rule. The key difference between the three cases lies in the replacement mechanism, which determines the strength of positive feedback and the degree of path dependence.

### Case 1: Standard Polya Urn (Figure 1)

**Implementation:** `standard_replacement()`

**Mechanism:** 
- Draw one ball with probability proportional to current counts
- Add 1 ball of the same color back to the urn

**Mathematical formulation:**

Let $n_i(t)$ denote the number of balls of color $i$ at time $t$, and $N(t) = \sum_i n_i(t)$ the total number of balls.

The probability of drawing color $i$ is:
$$P(\text{draw color } i \mid t) = \frac{n_i(t)}{N(t)}$$

The update rule is:
$$n_i(t+1) = \begin{cases} 
n_i(t) + 1 & \text{if color } i \text{ is drawn} \\
n_i(t) & \text{otherwise}
\end{cases}$$

**Properties:**
- Exhibits **weak dominance**: the share of each color converges to a stable value determined by early random events
- The expected share of color $i$ equals its initial share: $\mathbb{E}[\text{share}_i(\infty)] = \text{share}_i(0)$
- Final shares follow an approximately uniform distribution across runs
- Mean final share of dominant color: ~75%
- Demonstrates the preservation of early advantages through linear positive feedback

### Case 2: Higher Growth Polya Urn (Figure 2)

**Implementation:** `higher_growth_replacement()`

**Mechanism:**
- Draw one ball with probability proportional to current counts
- Add 3 balls of the same color back to the urn

**Mathematical formulation:**

The probability of drawing remains:
$$P(\text{draw color } i \mid t) = \frac{n_i(t)}{N(t)}$$

The update rule changes to:
$$n_i(t+1) = \begin{cases} 
n_i(t) + 3 & \text{if color } i \text{ is drawn} \\
n_i(t) & \text{otherwise}
\end{cases}$$

**Properties:**
- Exhibits **stronger dominance** than the standard case
- Faster divergence from balanced shares
- Earlier lock-in to stable configurations
- Mean final share of dominant color: ~85%
- Demonstrates that the magnitude of positive feedback (number of balls added) affects the speed and degree of path dependence
- Trajectories stabilize more quickly, with less variability in intermediate rounds

### Case 3: Probabilistic Replacement Rule (Figure 3)

**Implementation:** `probabilistic_replacement()`

**Mechanism:**
- Apply non-linear transformation to favor the currently dominant color
- Draw one ball with **over-proportional** probability for larger shares
- Add 1 ball of the drawn color back to the urn

**Mathematical formulation:**

Let $s_i(t) = \frac{n_i(t)}{N(t)}$ denote the share of color $i$ at time $t$.

The probability of drawing color $i$ uses a non-linear transformation:
$$P(\text{draw color } i \mid t) = \frac{s_i(t)^2}{\sum_j s_j(t)^2}$$

The update rule is:
$$n_i(t+1) = \begin{cases} 
n_i(t) + 1 & \text{if color } i \text{ is drawn} \\
n_i(t) & \text{otherwise}
\end{cases}$$

**Properties:**
- Exhibits **strong dominance**: most runs converge to near-complete dominance (>95%) of one color
- The squaring of shares amplifies differences, creating a "winner-takes-all" dynamic
- Trajectories diverge rapidly in early rounds
- Lock-in occurs earlier and more decisively than in Cases 1 and 2
- Mean final share of dominant color: >90%
- Demonstrates how non-linear positive feedback mechanisms can lead to extreme outcomes

### Case 4: Alternative Non-linear Replacement Rule (Figure 4)

**Implementation:** `arthur_nonlinear_replacement()`

**Mechanism:**
- Apply S-shaped non-linear transformation using $3x^2 - 2x^3$
- Draw one ball with over-proportional probability based on this transformation
- Add 1 ball of the drawn color back to the urn

**Mathematical formulation:**

Let $s_i(t) = \frac{n_i(t)}{N(t)}$ denote the share of color $i$ at time $t$.

The probability of drawing color $i$ uses an alternative non-linear transformation:
$$P(\text{draw color } i \mid t) = \frac{3s_i(t)^2 - 2s_i(t)^3}{\sum_j (3s_j(t)^2 - 2s_j(t)^3)}$$

The update rule is:
$$n_i(t+1) = \begin{cases} 
n_i(t) + 1 & \text{if color } i \text{ is drawn} \\
n_i(t) & \text{otherwise}
\end{cases}$$

**Properties:**
- The transformation function $f(x) = 3x^2 - 2x^3$ is S-shaped (sigmoid-like)
- Provides moderate amplification for intermediate shares (around 0.3-0.7)
- Stronger amplification once a color gains significant advantage
- More gradual path formation phase compared to Case 3
- The function is symmetric around $x = 0.5$: $f(0.5) = 0.5$
- Boundary conditions: $f(0) = 0$ and $f(1) = 1$
- Demonstrates how different non-linear feedback functions create distinct lock-in dynamics

### Comparison of mechanisms

| Case | Balls Added | Probability Rule | Dominance Type | Mean Final Share |
|------|-------------|------------------|----------------|------------------|
| 1. Standard | 1 | Linear (proportional) | Weak | ~75% |
| 2. Higher Growth | 3 | Linear (proportional) | Moderate | ~85% |
| 3. Probabilistic | 1 | Non-linear ($x^2$) | Strong | >90% |
| 4. Alternative Non-linear | 1 | Non-linear ($3x^2 - 2x^3$) | Strong | ~85-90% |

The four cases illustrate how different specifications of positive feedback mechanisms affect the degree of path dependence:
- **Case 1** shows that even minimal positive feedback (adding one ball) creates path dependence through cumulative causation
- **Case 2** demonstrates that increasing the magnitude of feedback accelerates lock-in
- **Case 3** shows that non-linear feedback mechanisms (simple squaring) can create winner-takes-all dynamics even with minimal additions per round
- **Case 4** illustrates how the shape of the non-linear transformation affects the dynamics: an S-shaped function provides more balanced competition in early rounds but strong lock-in once advantages emerge

All four cases share the fundamental characteristic of path dependence: early random events become amplified through positive feedback, leading to stable configurations that are difficult to reverse.

## Citation

These simulations recreate figures from:

Gräbner-Radkowitsch, C., & Kapeller, J. (forthcoming). 
Path Dependence. In W. Waller & W. Elsner (Eds.), 
*Elgar Encyclopedia of Institutional and Evolutionary Economics.*
Edward Elgar Publishing.

- [Working Paper Version](https://www.uni-due.de/imperia/md/content/soziooekonomie/ifsowp36_graebner-radkowitschkapeller_2024.pdf)
