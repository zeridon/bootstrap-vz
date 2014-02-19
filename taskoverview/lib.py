

def main(opts):
	import sys
	sys.path.append(opts['PATH'])

	classes = walk_classes([opts['PATH']])

	from common import phases
	from base import Task
	tasks = filter(lambda obj: issubclass(obj, Task) and obj is not Task, classes)

	def distinct(seq):
		seen = set()
		return [x for x in seq if x not in seen and not seen.add(x)]
	modules = distinct([task.__module__ for task in tasks])
	task_links = []
	task_links.extend([{'source': task,
	                    'target': succ,
	                    'definer': task,
	                    }
	                   for task in tasks
	                   for succ in task.successors])
	task_links.extend([{'source': pre,
	                    'target': task,
	                    'definer': task,
	                    }
	                   for task in tasks
	                   for pre in task.predecessors])

	def mk_phase(phase):
		return {'name': phase.name,
		        'description': phase.description,
		        }

	def mk_module(module):
		return {'name': module,
		        }

	def mk_node(task):
		return {'name': task.__name__,
		        'module': modules.index(task.__module__),
		        'phase': (i for i, phase in enumerate(phases.order) if phase is task.phase).next(),
		        }

	def mk_link(link):
		for key in ['source', 'target', 'definer']:
			link[key] = tasks.index(link[key])
		return link

	data = {'phases': map(mk_phase, phases.order),
	        'modules': map(mk_module, modules),
	        'nodes': map(mk_node, tasks),
	        'links': map(mk_link, task_links)}

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
	import importlib
	import inspect
	walker = pkgutil.walk_packages(path, '', walk_error)
	for _, module_name, _ in walker:
		module = importlib.import_module(module_name)
		classes = inspect.getmembers(module, inspect.isclass)
		for class_name, obj in classes:
			if obj.__module__ == module_name:
					yield obj


def walk_error(module):
	raise Exception('Unable to inspect module `{module}\''.format(module=module))
