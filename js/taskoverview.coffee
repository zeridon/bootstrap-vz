class window.TaskOverview
	viewPortWidth = 500
	viewPortHeight = 500
	arrowWidth = 6
	arrowHeight = 4
	nodeRadius = 5

	constructor: ({@selector}) ->
		@svg = d3.select(@selector)
			.attr('width', viewPortWidth)
			.attr('height', viewPortHeight)

		d3.json 'data/graph.json', @buildGraph

	buildGraph: (error, graph) =>
		@definitions = @svg.append 'defs'
		arrow = @definitions.append('marker')
		arrow.attr('id', 'right-arrowhead')
			.attr('refX', nodeRadius + arrowHeight)
			.attr('refY', arrowWidth/2)
			.attr('markerWidth', arrowHeight)
			.attr('markerHeight', arrowWidth)
			.attr('orient', 'auto')
		  .append('path').attr('d', "M0,0 V#{arrowWidth} L#{arrowHeight},#{arrowWidth/2} Z")
		@markers = arrow: arrow

		@layout = d3.layout.force()
				.linkDistance(30)
				.size([viewPortWidth, viewPortHeight])

		@layout.nodes(graph.nodes)
		@layout.links(graph.vertices)
		@layout.start()

		@links = @svg.selectAll('.link').data(graph.vertices).enter().append('line')
		@links.attr('class', 'link')
          .attr('marker-end', 'url(#right-arrowhead)')

		@nodes = @svg.selectAll('.node').data(graph.nodes).enter().append('circle')
		@nodes.attr('class', 'node')
			.attr('r', nodeRadius)
			.call(@layout.drag)
		@labels = @nodes.append('text')
			.attr('dx', 12)
			.attr('dy', '.35em')
			.text (d) -> d.name

		@layout.on 'tick', @tick

	tick: =>
		@links.attr('x1', (d) -> d.source.x)
					.attr('y1', (d) -> d.source.y)
					.attr('x2', (d) -> d.target.x)
					.attr('y2', (d) -> d.target.y)

		@nodes.attr('cx', (d) -> d.x)
					.attr('cy', (d) -> d.y)
