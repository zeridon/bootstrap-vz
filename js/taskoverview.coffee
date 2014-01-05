class window.TaskOverview
	viewBoxWidth = 800
	viewBoxHeight = 400
	margins =
		top:    0
		left:   100
		bottom: 10
		right:  100

	length = ([x,y]) -> Math.sqrt(x*x + y*y)
	sum = ([x1,y1], [x2,y2]) -> [x1+x2, y1+y2]
	diff = ([x1,y1], [x2,y2]) -> [x1-x2, y1-y2]
	prod = ([x,y], scalar) -> [x*scalar, y*scalar]
	div = ([x,y], scalar) -> [x/scalar, y/scalar]
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

	keyMap:
		phase: 'phases'
		module: 'modules'
	partition: (key, idx) ->
		return @data[@keyMap[key]]

	nodeRadius = 10
	nodePadding = 10
	createNodes: () ->
		options =
			gravity:      0
			linkDistance: 30
			linkStrength: .4
			charge:       -120
			size:         [viewBoxWidth, viewBoxHeight]

		layout = d3.layout.force()
		layout[option](value) for option, value of options

		array_sum = (list) -> list.reduce(((a,b) -> a + b), 0)
		partitioning =
			widths: do =>
				ratios = for _, i in @partition(partitionKey)
					Math.sqrt (task for task in @data.nodes when task[partitionKey] is i).length
				parts = (viewBoxWidth - margins.left - margins.right) / (array_sum ratios)
				widths = []
				for _, i in @partition(partitionKey)
					widths.push parts * ratios[i]
				return widths
			offset: (i) ->
				margins.left + array_sum @widths.slice(0, i)

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

		hullColors = d3.scale.category20()
		nodeColors = d3.scale.category20c()

		hulls = @svg.append('g').attr('class', 'hulls')
		            .selectAll('path').data(groups).enter()
		            .append('path').attr('id', (d) -> "hull-#{d.key}")
		                           .style
		                             'fill': (d, i) -> hullColors(i)
		                             'stroke': (d, i) -> hullColors(i)
		                             'stroke-linejoin': 'round'
		                             'stroke-width': 20
		
		hullLabels = @svg.append('g').attr('class', 'hull-labels')
		                 .selectAll('text').data(groups).enter()
		                 .append('text') #.attr('transform', 'translate(-40,0)')
		hullLabels.append('textPath').attr('xlink:href', (d) -> "#hull-#{d.key}")
		                             .text((d) => @partition(partitionKey)[d.key].name)

		links = @svg.append('g').attr('class', 'links')
		            .selectAll('line').data(layout.links()).enter()
		            .append('line').attr('marker-end', 'url(#right-arrowhead)')

		nodes = @svg.append('g').attr('class', 'nodes')
		            .selectAll('g.partition').data(groups).enter()
		            .append('g').attr('class', 'partition')
		            .selectAll('circle').data((d) -> d.values).enter()
		            .append('circle').attr('r', (d) -> d.radius)
		                             .style('fill', (d, i) -> nodeColors(d[nodeColorKey]))
		                             .call(layout.drag)
		                             .on('mouseover', (d) -> (labels.filter (l) -> d is l).classed 'hover', true )
		                             .on('mouseout', (d) -> (labels.filter (l) -> d is l).classed 'hover', false )

		labels = @svg.append('g').attr('class', 'node-labels')
		             .selectAll('g.partition').data(groups).enter()
		             .append('g').attr('class', 'partition')
		             .selectAll('text').data((d) -> d.values).enter()
		             .append('text').text((d) -> d.name)
		                            .attr('transform', (d) -> offset=-(d.radius + 5); "translate(0,#{offset})")


		unit_coords = [[-1,-1], [0,-1], [1,-1],
		               [-1, 0], [0, 0], [1, 0],
		               [-1, 1], [0, 1], [1, 1]]
		hullPointMatrix = (prod(v, nodeRadius*2) for v in unit_coords)
		hullBoundaries = (d) ->
			nodePoints = d.values.map (i) -> [i.x, i.y]
			padded_points = []
			padded_points.push sum(p, v) for v in hullPointMatrix for p in nodePoints
			points = d3.geom.hull(padded_points)
			# curvePoints = points.slice(1, points.length-(points.length-1)%2)
			# pairs = []
			# pairs.push(curvePoints.slice(i, i+2).join(' ')) for _, i in curvePoints by 2
			# curves = pairs.join('Q')
			# "M#{points[0]}Q#{curves}Z"
			"M#{points.join('L')}Z"

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
			links.each ({source:{x:x1,y:y1},target:{x:x2,y:y2}}, i) ->
				[x,y] = scale(free([[x1,y1], [x2,y2]]), nodeRadius)
				@setAttribute 'x1', x1 + x
				@setAttribute 'y1', y1 + y
				@setAttribute 'x2', x2 - x
				@setAttribute 'y2', y2 - y

		return layout
