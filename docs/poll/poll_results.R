# Shared poll ingestion, scoring, and plotting for the workshop slide.
# All five grid rows and option labels match the public form exactly.
poll_question <- "How experienced are you with the following AI workflows?"
poll_rows <- c(
  "Chat",
  "IDE with AI code extension (e.g., GitHub Copilot)",
  "Agents that can access, create and modify files via tool calling (e.g. Claude code, codex)",
  "Agent systems with tasked subagents and shared memory across tasks (e.g., OpenClaw, Hermes)",
  "Containerized workflows with embedded agents"
)
poll_choices <- c(
  "Never used it", "Tried it once", "Use it rarely",
  "Use it regularly", "Use it all the time"
)
poll_columns <- paste0(poll_question, " [", poll_rows, "]")
poll_plot_labels <- c(
  "Chat", "IDE with AI code extension", "File-editing / tool-calling agents",
  "Agent systems with subagents\nand shared memory", "Containerized agent workflows"
)

load_poll_data <- function(data_source = "mock", csv_url = "",
                           mock_path = "poll/mock_responses.csv",
                           live_path = "poll/live_responses.csv") {
  if (length(data_source) != 1L || !data_source %in% c("mock", "live")) {
    stop("poll_source must be 'mock' or 'live'.", call. = FALSE)
  }
  path <- if (data_source == "live") live_path else mock_path
  download_live <- data_source == "live" && !file.exists(path)
  if (download_live) {
    if (length(csv_url) != 1L || is.na(csv_url) ||
        !grepl("^https?://", csv_url)) {
      stop(paste(
        "Live mode needs poll_csv_url: a readable response-Sheet CSV URL.",
        "The forms.gle respondent URL does not expose responses."
      ), call. = FALSE)
    }
    path <- tempfile(tmpdir = dirname(live_path), fileext = ".csv")
    on.exit(unlink(path), add = TRUE)
    old_timeout <- getOption("timeout")
    options(timeout = max(45, old_timeout))
    on.exit(options(timeout = old_timeout), add = TRUE)
    status <- tryCatch(
      utils::download.file(csv_url, path, quiet = TRUE, mode = "wb",
                           method = "libcurl"),
      error = function(e) stop(
        "Could not download live responses. Check CSV URL and access; no mock fallback was used.",
        call. = FALSE
      )
    )
    if (status != 0L) stop("Live CSV download failed.", call. = FALSE)
  }
  if (!file.exists(path)) stop("Poll CSV does not exist: ", path, call. = FALSE)
  responses <- tryCatch(
    utils::read.csv(path, check.names = FALSE, stringsAsFactors = FALSE,
                    colClasses = "character", fileEncoding = "UTF-8-BOM",
                    na.strings = "", strip.white = TRUE),
    error = function(e) stop("Cannot read poll CSV: ", conditionMessage(e), call. = FALSE)
  )
  if (anyDuplicated(names(responses))) {
    stop("Poll CSV contains duplicate column headers.", call. = FALSE)
  }
  missing <- setdiff(poll_columns, names(responses))
  if (length(missing)) {
    stop(paste0(
      "Poll CSV is missing expected grid columns. Use a response-Sheet CSV export, ",
      "not the form page or a Google sign-in page.\nMissing: ",
      paste(missing, collapse = "\n")
    ), call. = FALSE)
  }
  scores <- lapply(seq_along(poll_columns), function(i) {
    values <- trimws(responses[[poll_columns[i]]])
    values[!is.na(values) & values == ""] <- NA_character_
    unexpected <- which(!is.na(values) & !values %in% poll_choices)
    if (length(unexpected)) {
      selections <- strsplit(values[unexpected], ",", fixed = TRUE)
      multiple <- vapply(selections, function(labels) {
        length(labels) > 1L && all(trimws(labels) %in% poll_choices)
      }, logical(1))
      if (any(!multiple)) {
        stop(sprintf("Unexpected answer label in the CSV for %s: %s",
                     poll_rows[i], paste(unique(values[unexpected[!multiple]]),
                                         collapse = "; ")),
             call. = FALSE)
      }
      warning(sprintf("Excluded %d poll response cell(s) with multiple selections for %s.",
                      length(unexpected), poll_rows[i]), call. = FALSE)
      values[unexpected] <- NA_character_
    }
    match(values, poll_choices) - 1L
  })
  summary <- do.call(rbind, lapply(seq_along(scores), function(i) {
    x <- scores[[i]]
    n <- sum(!is.na(x))
    data.frame(
      category = poll_plot_labels[i], n = n,
      mean = if (n) mean(x, na.rm = TRUE) else NA_real_,
      se = if (n > 1L) stats::sd(x, na.rm = TRUE) / sqrt(n) else NA_real_
    )
  }))
  if (nrow(responses) > 0L && any(summary$n == 0L)) {
    stop("At least one category has no valid answers; cannot plot all five means.", call. = FALSE)
  }
  if (download_live && !file.exists(live_path) && !file.rename(path, live_path)) {
    stop("Could not save live poll CSV: ", live_path, call. = FALSE)
  }
  summary$category <- factor(summary$category, levels = rev(poll_plot_labels))
  list(responses = responses, summary = summary, source = data_source)
}

plot_poll_results <- function(poll) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Install ggplot2 to render the poll chart.", call. = FALSE)
  }
  tint <- function(rgb, amount) grDevices::rgb(
    (rgb[1] * amount + 255 * (1 - amount)) / 255,
    (rgb[2] * amount + 255 * (1 - amount)) / 255,
    (rgb[3] * amount + 255 * (1 - amount)) / 255
  )
  # RGB values from materials/beamer_theme_trr266_16x9.sty, mixed with white.
  fills <- c(tint(c(20,103,107), .25), tint(c(110,202,226), .35),
             tint(c(255,180,59), .30), tint(c(148,70,100), .20),
             tint(c(34,75,79), .20))
  d <- poll$summary
  d$fill <- fills
  source_label <- if (poll$source == "mock") {
    sprintf("MOCK DATA — N = %d synthetic participants", nrow(poll$responses))
  } else {
    sprintf("LIVE POLL — N = %d respondents", nrow(poll$responses))
  }
  if (!nrow(poll$responses)) {
    return(
      ggplot2::ggplot() +
        ggplot2::annotate("text", x = .5, y = .58,
                          label = "No responses yet", size = 7, colour = "#14676B") +
        ggplot2::annotate("text", x = .5, y = .42,
                          label = "Rerender after participants have answered the poll.",
                          size = 4.5, colour = "#444444") +
        ggplot2::xlim(0, 1) + ggplot2::ylim(0, 1) +
        ggplot2::labs(title = source_label) +
        ggplot2::theme_void(base_family = "sans") +
        ggplot2::theme(
          plot.title = ggplot2::element_text(colour = "#14676B", face = "bold", size = 14),
          plot.margin = ggplot2::margin(5, 10, 5, 5)
        )
    )
  }
  ggplot2::ggplot(d, ggplot2::aes(x = mean, y = category)) +
    ggplot2::geom_col(ggplot2::aes(fill = fill), width = .60,
                      colour = "#14676B", linewidth = .35) +
    ggplot2::geom_errorbar(
      ggplot2::aes(xmin = mean - se, xmax = mean + se),
      orientation = "y", width = .20, linewidth = .6,
      colour = "#224B4F", na.rm = TRUE
    ) +
    ggplot2::scale_fill_identity() +
    ggplot2::scale_x_continuous(breaks = 0:4, limits = c(0, 4),
                               expand = ggplot2::expansion(mult = 0)) +
    ggplot2::labs(
      title = source_label,
      subtitle = "Mean experience score; whiskers show ±1 standard error",
      x = "0 Never used · 1 Tried once · 2 Rarely · 3 Regularly · 4 All the time",
      y = NULL,
      caption = "SE = sample SD / √n within each category."
    ) +
    ggplot2::theme_minimal(base_size = 12, base_family = "sans") +
    ggplot2::theme(
      plot.title = ggplot2::element_text(colour = "#14676B", face = "bold", size = 14),
      plot.subtitle = ggplot2::element_text(size = 11, margin = ggplot2::margin(b = 12)),
      axis.text.y = ggplot2::element_text(colour = "#222222", size = 11),
      axis.text.x = ggplot2::element_text(colour = "#444444"),
      axis.title.x = ggplot2::element_text(size = 10, margin = ggplot2::margin(t = 10)),
      panel.grid.major.y = ggplot2::element_blank(),
      panel.grid.minor = ggplot2::element_blank(),
      plot.caption = ggplot2::element_text(size = 8.5, hjust = 0,
                                          margin = ggplot2::margin(t = 10)),
      plot.margin = ggplot2::margin(5, 10, 5, 5)
    )
}
