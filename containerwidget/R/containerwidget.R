#' containerwidget
#'
#' containerwidget is a simple wrapper of \code{\link[htmlwidgets]{createWidget}}.
#'
#' @param html html as text (optional)
#' @param css css as text (optional)
#' @param javascript javascript as text (optional)
#' @param width width of element (optional) if NULL then use full window width
#' @param height height of element (optional) if NULL then use full window height
#'
#' @examples
#' css <- ".containerwidget {background-color:grey;}"
#' html <- "<b style=\"background-color:yellow;\">Text</b>"
#' javascript <- "alert('running');"
#' containerwidget(html = html, css = css, javascript = javascript)
#'
#' @import htmlwidgets
#'
#' @export
containerwidget <- function(html = NULL, css = NULL, javascript = NULL, width = NULL, height = NULL) {

  # forward options using x
  x = list(
    html = html,
    css = css,
    javascript = javascript
  )

  sizing <- htmlwidgets::sizingPolicy(padding = 0, browser.fill = TRUE)

  # create widget
  htmlwidgets::createWidget(
    name = 'containerwidget',
    x,
    width = width,
    height = height,
    package = 'containerwidget',
    sizingPolicy = sizing
  )
}

#' Widget output function for use in Shiny
#'
#' @export
containerwidgetOutput <- function(outputId, width = '100%', height = '400px'){
  shinyWidgetOutput(outputId, 'containerwidget', width, height, package = 'containerwidget')
}

#' Widget render function for use in Shiny
#'
#' @export
renderContainerwidget <- function(expr, env = parent.frame(), quoted = FALSE) {
  if (!quoted) { expr <- substitute(expr) } # force quoted
  shinyRenderWidget(expr, containerwidgetOutput, env, quoted = TRUE)
}
