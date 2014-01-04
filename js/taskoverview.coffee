class window.TaskOverview
	viewBoxWidth = 800
	viewBoxHeight = 400
	margins =
		top:    0
		left:   100
		bottom: 10
		right:  100

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

	buildGraph: (error, @data) =>
		@createDefinitions()
		taskLayout = @createNodes()
		taskLayout.start()

	createDefinitions: () ->
		definitions = @svg.append 'defs'
		arrow = definitions.append('marker')
		arrow.attr('id', 'right-arrowhead')
			.attr('refX', arrowHeight = 4)
			.attr('refY', 	(arrowWidth = 6) / 2)
			.attr('markerWidth', 	arrowHeight)
			.attr('markerHeight', arrowWidth)
			.attr('orient', 'auto')
		  .append('path').attr('d', "M0,0 V#{arrowWidth} L#{arrowHeight},#{arrowWidth/2} Z")

	partitionKey = 'phase'
	nodeColorKey = 'module'

	nodeRadius = 10
	nodePadding = 10
	createNodes: () ->
		options =
			gravity:      0
			linkDistance: 30
			linkStrength: .4
			charge:       -80
			size:         [viewBoxWidth, viewBoxHeight]

		layout = d3.layout.force()
		layout[option](value) for option, value of options

		sum = (list) -> list.reduce(((a,b) -> a + b), 0)
		partitioning =
			widths: do =>
				ratios = for _, i in @data[partitionKey+'s']
					Math.sqrt (task for task in @data.nodes when task[partitionKey] is i).length
				parts = (viewBoxWidth - margins.left - margins.right) / (sum ratios)
				widths = []
				for _, i in @data[partitionKey+'s']
					widths.push parts * ratios[i]
				return widths
			offset: (i) ->
				margins.left + sum @widths.slice(0, i)

		nodelist = for node in @data.nodes
			$.extend
				cx:     partitioning.offset(node[partitionKey]) + partitioning.widths[node[partitionKey]] / 2
				cy:     viewBoxHeight / 2 + margins.top
				radius: nodeRadius
				, node

		layout.nodes(nodelist)

		layout.links @data.links

		groups = d3.nest().key((d) -> d[partitionKey])
		                  .sortKeys(d3.ascending)
		                  .entries(nodelist)

		# svg
		# 	g.links
		# 		line
		# 	g.nodes
		# 		g.partition
		# 			path
		# 			g.tasks
		# 				circle
		# 			g.labels
		#					text
		# 		g.partition
		# 		...

		hullColors = d3.scale.category20()
		nodeColors = d3.scale.category20c()

		partitions = @svg.append('g').attr('class', 'nodes')
		                 .selectAll('g.partition').data(groups).enter()
		                 .append('g').attr('class', 'partition')

		hulls = partitions.append('path').attr('class', 'hull')
		                                 .style('fill', (d, i) -> hullColors(i))
		                                 .style('stroke', (d, i) -> hullColors(i))

		links = @svg.append('g').attr('class', 'links')
		            .selectAll('line').data(layout.links()).enter()
		            .append('line').attr('marker-end', 'url(#right-arrowhead)')

		nodes = partitions.append('g').attr('class', 'tasks').data(groups)
		                  .selectAll('circle').data((d) -> d.values).enter()
		                  .append('circle').attr('r', (d) -> d.radius)
		                                   .style('fill', (d, i) -> nodeColors(d[nodeColorKey]))
		                                   .call(layout.drag)
		                                   .on('mouseover', (d) -> (labels.filter (l) -> d is l).classed 'hover', true )
		                                   .on('mouseout', (d) -> (labels.filter (l) -> d is l).classed 'hover', false )

		labels = partitions.append('g').attr('class', 'labels').data(groups)
		                   .selectAll('text').data((d) -> d.values).enter()
		                   .append('text').text((d) -> d.name)
		                                  .attr('transform', (d) -> offset=-(d.radius + 5); "translate(0,#{offset})")


		hullBoundaries = (d) ->
			lines = d3.geom.hull(d.values.map((i) -> [i.x, i.y])).join("L")
			"M#{lines}Z"

		gravity = (alphax, alphay) =>
			(d) ->
				d.x += (d.cx - d.x) * alphax
				d.y += (d.cy - d.y) * alphay

		layout.on 'tick', (e) =>
			hulls.attr('d', hullBoundaries)
			nodes.each gravity(.2 * e.alpha, .08 * e.alpha)
			nodes.attr
				cx: ({x}) -> x
				cy: ({y}) -> y
			labels.each gravity(.2 * e.alpha, .08 * e.alpha)
			labels.attr
				x: ({x}) -> x
				y: ({y}) -> y
			links.each ({source, target}, i) ->
				shrinkBy = scale(free([source,target]), nodeRadius)
				@setAttribute 'x1', source.x + shrinkBy.x
				@setAttribute 'y1', source.y + shrinkBy.y
				@setAttribute 'x2', target.x - shrinkBy.x
				@setAttribute 'y2', target.y - shrinkBy.y

		return layout
