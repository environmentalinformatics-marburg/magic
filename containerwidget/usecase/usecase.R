library(containerwidget)

css <- ".containerwidget {background-color:grey;}"

html <- "<b style=\"background-color:yellow;\">Text</b>"

javascript <- "alert('running');"


containerwidget(html = html, css = css, javascript = javascript, 100, 100)
