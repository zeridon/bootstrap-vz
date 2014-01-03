

def main(opts):
	import sys
	sys.path.append(opts['PATH'])

	classes = walk_classes([opts['PATH']])

	from common import phases
	phase_links = [{'source': phases.order[i],
	                'target': phases.order[i+1],
	                } for i in range(0, len(phases.order)-2)]

	from base import Task
	task_nodes = filter(lambda obj: issubclass(obj, Task) and obj is not Task, classes)
	task_links = []
	task_links.extend([{'source': task,
	                    'target': succ,
	                    'definer': task,
	                    }
	                   for task in task_nodes
	                   for succ in task.successors])
	task_links.extend([{'source': pre,
	                    'target': task,
	                    'definer': task,
	                    }
	                   for task in task_nodes
	                   for pre in task.predecessors])

	data = {'phases': {'nodes': phases.order,
	                   'links': phase_links,
	                   },
	        'tasks': {'nodes': task_nodes,
	                  'links': task_links,
	                  }
	        }

	def mk_lookup(data, *keys):
		def lookup(obj):
			for key in keys:
				obj[key] = data.index(obj[key])
			return obj
		return lookup

	data['phases']['links'] = map(mk_lookup(data['phases']['nodes'], 'source', 'target'),
	                              data['phases']['links'])
	data['tasks']['links'] = map(mk_lookup(data['tasks']['nodes'], 'source', 'target', 'definer'),
	                             data['tasks']['links'])

	def create_task_node(task):
		return {'name': task.__name__,
		        'module': task.__module__,
		        'phase': task.phase,
		        }

	data['tasks']['nodes'] = map(create_task_node, data['tasks']['nodes'])
	data['tasks']['nodes'] = map(mk_lookup(data['phases']['nodes'], 'phase'),
	                             data['tasks']['nodes'])

	def create_phase_node(phase):
		return {'name': phase.name,
		        'description': phase.description,
		        }

	data['phases']['nodes'] = map(create_phase_node, data['phases']['nodes'])

	write_data(data, opts.get('--output', None))


def write_data(data, output_path=None):
	import json
	if output_path is None:
		import sys
		json.dump(data, sys.stdout, indent=4, separators=(',', ': '))
	else:
		with open(output_path, 'w') as output:
			json.dump(data, output)


def walk_classes(path=None):
	import pkgutil
	import inspect
	import sys
	walker = pkgutil.walk_packages(path, '', walk_error)
	for _, module_name, _ in walker:
		__import__(module_name)
		classes = inspect.getmembers(sys.modules[module_name], inspect.isclass)
		for class_name, obj in classes:
			if obj.__module__ == module_name:
					yield obj


def walk_error(module):
	raise Exception('Unable to inspect module `{module}\''.format(module=module))
