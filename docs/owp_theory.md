# OWP Theory: Information-Theoretic Optimal Well Placement

## 1. Problem Statement

Given a 2D binary random field **X** = {X_ij} of size H x W representing geological facies (e.g., sand vs. shale), and a budget of K measurement positions (wells), find the set of K positions **f** = {(r_1,c_1), ..., (r_K,c_K)} that maximizes the information gained about the entire field.

The field is modeled as a realization of a spatially correlated binary random process, where prior knowledge about spatial patterns is encoded in a **Training Image** (TI).

## 2. Information-Theoretic Foundations

### 2.1 Shannon Entropy

For a discrete random variable X with probability mass function P(x):

    H(X) = -sum_x P(x) * log2(P(x))

Properties:
- H(X) >= 0 (non-negativity)
- H(X) = 0 iff X is deterministic
- H(X) <= log2(|X|) (maximum for uniform distribution)

### 2.2 Binary Entropy

For a Bernoulli random variable X ~ Bernoulli(p):

    H_bin(p) = -p * log2(p) - (1-p) * log2(1-p)

Properties:
- H_bin(0) = H_bin(1) = 0 (certainty)
- H_bin(0.5) = 1 bit (maximum uncertainty)
- H_bin(p) = H_bin(1-p) (symmetry)
- H_bin is concave on [0, 1]

### 2.3 Joint Entropy

For a collection of random variables X_1, ..., X_N:

    H(X_1, ..., X_N) = -sum P(x_1,...,x_N) * log2(P(x_1,...,x_N))

Chain rule decomposition:

    H(X_1, ..., X_N) = sum_{i=1}^{N} H(X_i | X_1, ..., X_{i-1})

### 2.4 Conditional Entropy

    H(X | Y) = -sum_{x,y} P(x,y) * log2(P(x|y))
             = H(X,Y) - H(Y)

For the OWP problem:
- H(X^f | X_f) is the **posterior uncertainty** about unmeasured positions X^f given measurements X_f
- This is what we want to minimize

### 2.5 Mutual Information

    I(X; Y) = H(X) - H(X|Y) = H(Y) - H(Y|X) = H(X) + H(Y) - H(X,Y)

Properties:
- I(X; Y) >= 0
- I(X; Y) = I(Y; X) (symmetric)
- I(X; Y) = 0 iff X and Y are independent

## 3. Optimal Placement Formulation

### 3.1 The Optimization Problem

Let F_K denote all possible subsets of K positions from the H*W grid. The optimal placement is:

    f* = argmax_{f in F_K} H(X_f)

### 3.2 Equivalent Formulations

The following three objectives are equivalent (since H(X) is constant):

1. **Maximize measurement entropy**: max_{f} H(X_f)
2. **Minimize posterior uncertainty**: min_{f} H(X^f | X_f)
3. **Maximize mutual information**: max_{f} I(X_f; X^f)

Proof of equivalence:

    H(X) = H(X_f) + H(X^f | X_f)    [chain rule]

Since H(X) is constant:

    max H(X_f) <=> min H(X^f | X_f)

And:

    I(X_f; X^f) = H(X_f) - H(X_f | X^f) = H(X^f) - H(X^f | X_f)

Since H(X^f) is constant for fixed |f|:

    max I(X_f; X^f) <=> min H(X^f | X_f) <=> max H(X_f)

### 3.3 Computational Complexity

The combinatorial optimization over F_K is NP-hard in general. The number of candidate sets is:

    |F_K| = C(H*W, K) = (H*W)! / (K! * (H*W - K)!)

For a 64x64 grid with K=20: |F_K| ~ 10^55, intractable.

## 4. Greedy Approximation (AdSEMES)

### 4.1 Submodularity

The entropy function f(S) = H(X_S) is **monotone submodular**:

- **Monotone**: S subset T => f(S) <= f(T)
- **Submodular**: f(S union {i}) - f(S) >= f(T union {i}) - f(T) for S subset T

This means adding a new measurement always helps, but the marginal benefit decreases as more measurements are made (diminishing returns).

### 4.2 Greedy Algorithm

The greedy algorithm iteratively selects the position that maximizes the marginal entropy gain:

```
Algorithm: AdSEMES (Adaptive Sequential Empirical Maximum Entropy Sampling)

Input: Training Image TI, field dimensions (H, W), budget K, radius r
Output: Ordered measurement set f* = {i*_1, ..., i*_K}

1. Initialize:
   - field = empty (all unknown)
   - sampled = {}
   - f* = {}

2. For k = 1, 2, ..., K:
   a. For each unsampled position i:
      - Extract neighborhood pattern from field
      - Count matching patterns in TI
      - Estimate P(X_i = 1 | known neighbors)
      - Compute H_est(i) = H_bin(P(X_i = 1 | known neighbors))

   b. Select: i*_k = argmax_{i not in sampled} H_est(i)

   c. Reveal: field[i*_k] = true_field[i*_k]

   d. Update: sampled = sampled union {i*_k}
              f* = f* union {i*_k}

3. Return f*
```

### 4.3 Optimality Guarantee

By the classical result of Nemhauser, Wolsey, and Fisher (1978):

For monotone submodular function maximization with cardinality constraint:

    f(S_greedy) >= (1 - 1/e) * f(S_optimal)

where e ~ 2.718. This guarantees the greedy solution achieves at least 63.2% of the optimal information gain.

### 4.4 Complexity

- Naive: O(K * N * TI_H * TI_W * patch_size) where N = H*W
- With vectorization: O(K * N * TI_H * TI_W) with small constant
- The fast implementation uses numpy broadcasting for the TI scanning

## 5. Pattern Statistics from Training Images

### 5.1 Training Image

A Training Image (TI) is a conceptual model of the expected spatial patterns. It encodes:
- Facies proportions (P(X=1))
- Two-point statistics (variogram)
- Multi-point statistics (higher-order spatial patterns)
- Connectivity and geometry of geological features

### 5.2 Pattern Matching

For a template of size (2r+1) x (2r+1) centered at position i:
- Extract the local neighborhood of known values
- Scan the TI for all patches matching the known pattern
- Estimate: P(X_i = 1 | pattern) = count(center=1) / count(all matches)

### 5.3 Conditional Probability Estimation

    P(X_i = 1 | neighbors) = N_1 / (N_1 + N_0)

where:
- N_1 = number of TI patches matching the known pattern with center = 1
- N_0 = number of TI patches matching the known pattern with center = 0

If no matches are found, fall back to the marginal: P(X_i = 1) = mean(TI).

## 6. Resolvability Capacity

### 6.1 Definition

    C_k = I(f*_k) / H(X)

where:
- I(f*_k) = H(X) - H(X | X_{f*_k}) is the information gained after k measurements
- H(X) is the total prior entropy

### 6.2 Properties

- C_0 = 0 (no measurements, no information)
- C_k in [0, 1]
- C_{k+1} >= C_k (monotonically non-decreasing)
- C_N = 1 (all positions measured, complete information)
- The rate of increase indicates sampling efficiency

### 6.3 Interpretation

- C_k ~ 0.5: half the field uncertainty has been resolved
- C_k ~ 0.9: most uncertainty resolved, diminishing returns
- Comparing C_k curves across methods shows relative efficiency

## 7. Sampling Schemes Comparison

| Method | Adaptive | Uses TI | Uses Truth | Complexity | Expected Quality |
|--------|----------|---------|------------|------------|-----------------|
| Random Uniform | No | No | No | O(K) | Baseline |
| Stratified Grid | No | No | No | O(K) | Good coverage |
| Random Stratified | No | No | No | O(K) | Coverage + randomization |
| Multiscale | No | No | No | O(K) | Multi-resolution |
| Oracle Entropy | Yes | No | Yes | O(K*N) | Upper bound |
| AdSEMES | Yes | Yes | No* | O(K*N*TI) | Near-optimal |

*AdSEMES uses the true field only to reveal values at selected positions (simulating drilling).

## 8. Reconstruction Methods

### 8.1 Nearest Neighbor
Assign each unsampled position the value of its closest sample.
- Voronoi tessellation
- No smoothing
- O(N log K) with KD-tree

### 8.2 Indicator Kriging
Linear estimation with weights from variogram:
- Exponential variogram: gamma(h) = c_0 + c * (1 - exp(-3h/a))
- Solve kriging system: C * w = c for each target position
- BLUE (Best Linear Unbiased Estimator)
- O(N * K_nn^3) for K_nn neighbors

### 8.3 Entropy-Weighted IDW
Inverse-distance weighting modulated by entropy:
- w_ij = (1/d_ij^p) * (1 - H_j/H_max)
- Heuristic, accounts for local uncertainty
- O(N * K)

## 9. Performance Metrics

### 9.1 SNR (Signal-to-Noise Ratio)
    SNR = 10 * log10(||x||^2 / ||x - x_hat||^2) [dB]

### 9.2 MSE (Mean Squared Error)
    MSE = (1/N) * sum (x_i - x_hat_i)^2

### 9.3 Classification Accuracy
    Acc = (TP + TN) / (TP + TN + FP + FN)

### 9.4 Pattern Preservation
Autocorrelation similarity between true and reconstructed fields at short lags.

## 10. References

1. Shannon, C. E. (1948). A Mathematical Theory of Communication. Bell System Technical Journal, 27(3), 379-423.

2. Cover, T. M., & Thomas, J. A. (2006). Elements of Information Theory (2nd ed.). Wiley-Interscience.

3. Nemhauser, G. L., Wolsey, L. A., & Fisher, M. L. (1978). An analysis of approximations for maximizing submodular set functions. Mathematical Programming, 14(1), 265-294.

4. Strebelle, S. (2002). Conditional simulation of complex geological structures using multiple-point statistics. Mathematical Geology, 34(1), 1-21.

5. Mariethoz, G., & Caers, J. (2015). Multiple-point Geostatistics: Stochastic Modeling with Training Images. Wiley.

6. Goovaerts, P. (1997). Geostatistics for Natural Resources Evaluation. Oxford University Press.

7. Chiles, J. P., & Delfiner, P. (2012). Geostatistics: Modeling Spatial Uncertainty (2nd ed.). Wiley.

8. Silva, J. F., et al. IDS Group, Universidad de Chile. Fondecyt Grant 1140840.

9. Krause, A., & Guestrin, C. (2005). Near-optimal nonmyopic value of information in graphical models. UAI 2005.

10. Caselton, W. F., & Zidek, J. V. (1984). Optimal monitoring network designs. Statistics & Probability Letters, 2(4), 223-227.

11. Ko, C. W., Lee, J., & Queyranne, M. (1995). An exact algorithm for maximum entropy sampling. Operations Research, 43(4), 684-691.

12. Journel, A. G. (1983). Nonparametric estimation of spatial distributions. Journal of the International Association for Mathematical Geology, 15(3), 445-468.
