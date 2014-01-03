

def main(opts):
	import sys
	sys.path.append(opts['PATH'])

	def walk_error(module):
		raise Exception('Unable to inspect module `{module}\''.format(module=module))
	classes = walk_classes([opts['PATH']], onerror=walk_error)

	data = {}

	def obj_idx(obj, list):
		for i, item in enumerate(list):
			if item['obj'] is obj:
				return i
		raise Exception('`{obj}\' not found in list'.format(obj=obj))

	data['phases'] = []
	from common import phases
	for phase in phases.order:
		data['phases'].append({'obj': phase,
		                       'name': phase.name, })

	data['nodes'] = []
	from base import Task
	for obj in classes:
		if issubclass(obj, Task) and obj is not Task:
			data['nodes'].append({'obj': obj,
			                      'name': obj.__module__ + '.' + obj.__name__,
			                      'phase': obj_idx(obj.phase, data['phases']),
			                      })

	data['vertices'] = []
	for i, node in enumerate(data['nodes']):
		for task in node['obj'].predecessors:
			data['vertices'].append({'source': obj_idx(task, data['nodes']),
			                         'target': i,
			                         })
		for task in node['obj'].successors:
			data['vertices'].append({'source': i,
			                         'target': obj_idx(task, data['nodes']),
			                         })
	data['phases'] = [phase['name'] for phase in data['phases']]
	for node in data['nodes']:
		del node['obj']

	write_data(data, opts.get('output', None))


def write_data(data, output_path=None):
	import json
	if output_path is None:
		import sys
		json.dump(data, sys.stdout, indent=4, separators=(',', ': '))
	else:
		with open(output_path) as output:
			json.dump(data, output)


def walk_classes(path=None, prefix='', onerror=None):
	import pkgutil
	import inspect
	import sys
	walker = pkgutil.walk_packages(path, prefix, onerror)
	for _, module_name, _ in walker:
		__import__(module_name)
		classes = inspect.getmembers(sys.modules[module_name], inspect.isclass)
		for class_name, obj in classes:
			if obj.__module__ == module_name:
					yield obj
