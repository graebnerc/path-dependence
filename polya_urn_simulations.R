# Load required libraries --------------------------------------------------
here::i_am("polya_urn_simulations.R")
library(here)
library(readr)
library(scales)
library(dplyr)
library(ggplot2)
library(patchwork)

# Set random seed for reproducibility
set.seed(123)

# Helper Functions ---------------------------------------------------------

#' Standard Polya Urn Simulation
#' 
#' @param n_rounds Number of rounds to simulate
#' @param initial_balls Vector of initial ball counts per color
#' @param replacement_rule Function defining replacement mechanism
#' @return Data frame with columns: t (time), color, count, share
simulate_polya_urn <- function(n_rounds, 
                               initial_balls = c(1, 1),
                               replacement_rule = standard_replacement) {
  
  n_colors <- length(initial_balls)
  balls <- initial_balls
  
  # Store results
  results <- vector("list", n_rounds)
  
  for (t in 1:n_rounds) {
    # Store current state
    total_balls <- sum(balls)
    results[[t]] <- data.frame(
      t = t,
      color = 1:n_colors,
      count = balls,
      share = balls / total_balls
    )
    
    # Draw a ball and apply replacement rule
    balls <- replacement_rule(balls)
  }
  
  bind_rows(results)
}

#' Standard Replacement Rule: Draw 1, add 1 of same color
standard_replacement <- function(balls) {
  total <- sum(balls)
  probs <- balls / total
  drawn_color <- sample(length(balls), 1, prob = probs)
  balls[drawn_color] <- balls[drawn_color] + 1
  return(balls)
}

#' Higher Growth Replacement Rule: Draw 1, add 3 of same color
higher_growth_replacement <- function(balls) {
  total <- sum(balls)
  probs <- balls / total
  drawn_color <- sample(length(balls), 1, prob = probs)
  balls[drawn_color] <- balls[drawn_color] + 3
  return(balls)
}

#' Probabilistic Replacement Rule: 
#'  Over-proportional probability for dominant color
#' This creates strong dominance
probabilistic_replacement <- function(balls) {
  total <- sum(balls)
  shares <- balls / total
  
  # Apply non-linear transformation to favor dominant color
  # Using exponential weighting
  probs <- shares^2
  probs <- probs / sum(probs)
  
  drawn_color <- sample(length(balls), 1, prob = probs)
  balls[drawn_color] <- balls[drawn_color] + 1
  return(balls)
}

#' Alternative Non-linear Replacement Rule: 
#'  Uses 3x^2 - 2x^3 transformation
#' Creates different dominance pattern than simple squaring, used by Arthur
arthur_nonlinear_replacement <- function(balls) {
  total <- sum(balls)
  shares <- balls / total
  
  # Apply non-linear transformation: 3x^2 - 2x^3
  # This function is S-shaped and amplifies intermediate differences
  transformed <- 3 * shares^2 - 2 * shares^3
  probs <- transformed / sum(transformed)
  
  drawn_color <- sample(length(balls), 1, prob = probs)
  balls[drawn_color] <- balls[drawn_color] + 1
  return(balls)
}

#' Run multiple simulations
#' 
#' @param n_runs Number of simulation runs
#' @param n_rounds Number of rounds per run
#' @param initial_balls Initial ball configuration
#' @param replacement_rule Replacement mechanism function
#' @return Data frame with run_id, t, color, count, share
run_multiple_simulations <- function(n_runs, 
                                     n_rounds, 
                                     initial_balls = c(1, 1),
                                     replacement_rule = standard_replacement) {
  
  results <- vector("list", n_runs)
  
  for (i in 1:n_runs) {
    sim_result <- simulate_polya_urn(n_rounds, initial_balls, replacement_rule)
    sim_result$id <- i
    results[[i]] <- sim_result
  }
  
  bind_rows(results)
}

#' Extract final shares from multiple runs
#' 
#' @param sim_data Data frame from run_multiple_simulations
#' @return Data frame with id and share_top_color
extract_final_shares <- function(sim_data) {
  sim_data %>%
    group_by(id) %>%
    filter(t == max(t)) %>%
    summarise(share_top_color = max(share)) %>%
    ungroup()
}

# Visualization Functions --------------------------------------------------

#' Create typical runs plot (left panel of figures)
plot_typical_runs <- function(
    sim_data, n_display = 6, title = "Standard Polya Urn: Typical runs") {
  
  # Select a subset of runs to display
  selected_ids <- unique(
    sim_data$id)[1:min(n_display, length(unique(sim_data$id)))]
  
  plot_data <- sim_data %>%
    filter(id %in% selected_ids, color == 1) %>%
    arrange(id, t)
  
  ggplot(plot_data, aes(x = t, y = share, color = as.factor(id), group = id)) +
    geom_line(linewidth = 0.8) +
    scale_color_manual(
      values = c(rep("#FF8C00", n_display/2), rep("#8B008B", n_display/2))) +
    scale_y_continuous(labels = scales::percent_format(), limits = c(0, 1)) +
    labs(
      title = title,
      x = "Number of rounds played",
      y = "Share of each color"
    ) +
    theme_minimal(base_size = 13) +
    theme(
      legend.position = "none",
      panel.grid.minor = element_blank(),
      plot.title = element_text(size = 14, face = "bold"),
      axis.text = element_text(size = 12)
    )
}

#' Create distribution of outcomes plot (right panel of figures)
plot_distribution <- function(
    final_shares, title = "Standard Polya Urn: Distribution of outcomes") {
  
  # Calculate mean for vertical line
  mean_share <- mean(final_shares$share_top_color)
  
  ggplot(final_shares, aes(x = id, y = share_top_color)) +
    geom_point(
      alpha = 0.6, size = 2, color = "#8B008B") +
    geom_point(
      aes(y = mean_share), color = "#FF8C00", size = 2, alpha = 0.6) +
    geom_hline(
      yintercept = 0.5, linetype = "dashed", color = "gray50", alpha = 0.5) +
    scale_y_continuous(
      labels = percent_format(), limits = c(0, 1)) +
    labs(
      title = title,
      x = "Model run",
      y = "Share of dominant color across runs (%)"
    ) +
    annotate("text", x = max(final_shares$id) * 0.35, y = 0.15, 
             label = "share of dominant color across runs", 
             color = "#8B008B", size = 5, hjust = 0) +
    annotate("point", x = max(final_shares$id) * 0.33, y = 0.15, 
             color = "#8B008B", size = 4, alpha = 0.6) +
    annotate("text", x = max(final_shares$id) * 0.35, y = 0.10, 
             label = "mean value across runs", 
             color = "#FF8C00", size = 5, hjust = 0) +
    annotate("point", x = max(final_shares$id) * 0.33, y = 0.10, 
             color = "#FF8C00", size = 4, alpha = 0.6) +
    theme_minimal(base_size = 13) +
    theme(
      panel.grid.minor = element_blank(),
      plot.title = element_text(size = 14, face = "bold"),
      axis.text = element_text(size = 12)
    )
}

#' Create combined figure (both panels)
create_figure <- function(
    sim_data, n_display = 6, title_prefix = "Standard Polya Urn") {
  
  final_shares <- extract_final_shares(sim_data)
  
  p1 <- plot_typical_runs(
    sim_data, n_display, paste0(title_prefix, ": Typical runs"))
  p2 <- plot_distribution(
    final_shares, paste0(title_prefix, ": Distribution of outcomes"))
  
  p1 + p2
}

# Main Simulation Code -----------------------------------------------------

# Figure 1: Standard Polya Urn Model
message("Simulating Figure 1: Standard Polya Urn Model...")
fig1_data <- run_multiple_simulations(
  n_runs = 500,
  n_rounds = 200,
  initial_balls = c(1, 1),
  replacement_rule = standard_replacement
)
write_csv(x = fig1_data, file = here("data/figure_1.csv"))

fig1_plot <- create_figure(
  fig1_data, n_display = 16, title_prefix = "Standard Polya Urn")

# Save Figure 1
ggsave(here("figures/figure1_standard_polya.pdf"), 
       fig1_plot, width = 12, height = 5)
message("Figure 1 saved as 'figure1_standard_polya.pdf'")

# Figure 2: Higher Growth Polya Urn Model (add 3 balls instead of 1)
message("\nSimulating Figure 2: Higher Growth Polya Urn Model...")
fig2_data <- run_multiple_simulations(
  n_runs = 500,
  n_rounds = 200,
  initial_balls = c(1, 1),
  replacement_rule = higher_growth_replacement
)
write_csv(x = fig2_data, file = here("data/figure_2.csv"))

fig2_plot <- create_figure(
  fig2_data, n_display = 16, title_prefix = "Polya Urn (higher growth)")

# Save Figure 2
ggsave(here("figures/figure2_higher_growth_polya.pdf"), 
       fig2_plot, width = 12, height = 5)
message("Figure 2 saved as 'figure2_higher_growth_polya.pdf'")

# Figure 3: Probabilistic Replacement Rule (strong dominance)
message("\nSimulating Figure 3: Probabilistic Replacement Rule...")
fig3_data <- run_multiple_simulations(
  n_runs = 500,
  n_rounds = 200,
  initial_balls = c(1, 1),
  replacement_rule = probabilistic_replacement
)
write_csv(x = fig3_data, file = here("data/figure_3_1000.csv"))

fig3_plot <- create_figure(
  fig3_data, n_display = 16, title_prefix = "Polya Urn (prob. replacement)")

# Save Figure 3
ggsave(here("figures/figure3_probabilistic_polya_1000.pdf"), 
       fig3_plot, width = 12, height = 5)
message("Figure 3 saved as 'figure3_probabilistic_polya.pdf'")

# Figure 3: Probabilistic Replacement Rule (strong dominance)
message("\nSimulating Figure 4: Arthurs probabilistic Replacement Rule...")
fig4_data <- run_multiple_simulations(
  n_runs = 500,
  n_rounds = 200,
  initial_balls = c(1, 1),
  replacement_rule = arthur_nonlinear_replacement
)
write_csv(x = fig4_data, file = here("data/figure_4.csv"))

fig4_plot <- create_figure(
  fig4_data, n_display = 16, 
  title_prefix = "Polya Urn (pr. replacement II)")

# Save Figure 4
ggsave(here("figures/figure4_probabilistic_polya.pdf"), 
       fig4_plot, width = 12, height = 5)
message("Figure 4 saved as 'figure3_probabilistic_polya.pdf'")

message("\n=== Simulation Complete ===")
