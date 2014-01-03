class window.TaskOverview
	viewBoxWidth = 800
	viewBoxHeight = 400
	arrowWidth = 6
	arrowHeight = 4
	nodeRadius = 5

	length = ({x,y}) -> Math.sqrt(x*x + y*y)
	sum = ({x:x1,y:y1}, {x:x2,y:y2}) -> {x:x1+x2, y:y1+y2}
	diff = ({x:x1,y:y1}, {x:x2,y:y2}) -> {x:x1-x2, y:y1-y2}
	prod = ({x,y}, scalar) -> {x:x*scalar, y:y*scalar}
	div = ({x,y}, scalar) -> {x:x/scalar, y:y/scalar}
	unit = (vector) -> div(vector, length(vector))
	scale = (vector, scalar) -> prod(unit(vector), scalar)
	position = (coord, vector) -> [coord, sum(coord, vector)]

	free = ([coord1, coord2]) -> diff(coord2, coord1)
	pmult = (pvector=[coord1, _], scalar) -> position(coord1, prod(free(pvector), scalar))
	pdiv = (pvector=[coord1, _], scalar) -> position(coord1, div(free(pvector), scalar))

	constructor: ({@selector}) ->
		@svg = d3.select(@selector)
			.attr('viewBox', "0 0 #{viewBoxWidth} #{viewBoxHeight}")

		d3.json 'data/graph.json', @buildGraph

	buildGraph: (error, graph) =>
		@definitions = @svg.append 'defs'
		arrow = @definitions.append('marker')
		arrow.attr('id', 'right-arrowhead')
			.attr('refX', arrowHeight)
			.attr('refY', arrowWidth/2)
			.attr('markerWidth', arrowHeight)
			.attr('markerHeight', arrowWidth)
			.attr('orient', 'auto')
		  .append('path').attr('d', "M0,0 V#{arrowWidth} L#{arrowHeight},#{arrowWidth/2} Z")
		@markers = arrow: arrow

		@layout = d3.layout.force()
			.linkDistance(30)
			.size([viewBoxWidth, viewBoxHeight])

		@layout.nodes(graph.tasks.nodes)
		@layout.links(graph.tasks.links)
		@layout.start()

		@nodes = @svg.append('g').attr('class', 'tasks')
		                         .selectAll('circle.node').data(@layout.nodes())
		                         .enter().append('circle').attr('class', 'node')
		@nodes.attr('r', nodeRadius)
			    .call(@layout.drag)

		@labels = @svg.append('g').attr('class', 'tasks')
		                         .selectAll('text.label').data(@layout.nodes())
		                         .enter().append('text').attr('class', 'label')
		@labels.text (d) -> d.name

		@links = @svg.append('g').attr('class', 'tasks')
		                         .selectAll('line.link').data(@layout.links())
		                         .enter().append('line').attr('class', 'link')
		@links.attr('marker-end', 'url(#right-arrowhead)')

		@layout.on 'tick', @tick

	tick: =>
		@nodes.attr('cx', (d) -> d.x)
					.attr('cy', (d) -> d.y)
		@labels.attr('x', (d) -> d.x)
					 .attr('y', (d) -> d.y)
		@links.attr('x1', ({source,target}) -> source.x + scale(free([source,target]), nodeRadius).x)
		      .attr('y1', ({source,target}) -> source.y + scale(free([source,target]), nodeRadius).y)
		      .attr('x2', ({source,target}) -> target.x - scale(free([source,target]), nodeRadius).x)
		      .attr('y2', ({source,target}) -> target.y - scale(free([source,target]), nodeRadius).y)
