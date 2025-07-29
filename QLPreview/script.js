// data types

function nullV() { return '<span class="null">null</span>'; }
function boolV(val) { return '<span class="bool">' + html(val) + '</span>'; }
function numV(val) { return '<span class="num">' + html(val) + '</span>'; }
function stringV(val) { return '<span class="string">"' + jstr(val) + '"</span>'; }
function linkV(val) { return '"<a href="' + encodeURI(val) + '">' + jstr(val) + '</a>"'; }
function propK(key) { return '<span class="prop">"' + jstr(key) + '"</span>'; }

function wrapJSONP(callback, json, suffix) {
	return `<span class="callback">${callback}(</span>${json}<span class="callback">)${suffix}</span>`;
}
function errorPage(error, json) {
	return '<p class="error">Error parsing JSON:<br>' + error + '</p><h1>Content:</h1><pre>' + html(json) + '</pre>';
}

// helper

function indent(nl, level) { return nl ? nl + '&nbsp; '.repeat(level) : ''; }
function jstr(s) { return html(JSON.stringify(s).slice(1, -1)); }
function html(s) {
	return (s + '').replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');
}

// formatter entry point

function init() {
	document.body.innerHTML = parse(document.getElementById('json').textContent);
}

function parse(raw) {
	let data = raw, callback = '', suffix = '';
	// matches "callback({json});" ... original had \s -> [\s\u200B\uFEFF]
	let match = /^\s*([\w$\[\]\.]+)\s*\(\s*([\[{][\s\S]*[\]}])\s*\)([\s;]*)$/m.exec(raw);
	if (match && match.length === 4) {
		callback = match[1];
		data = match[2];
		suffix = match[3].replace(/[^;]+/g, '');
	}

	try {
		let root = nested(JSON.parse(data), 0, '<br>');
		if (callback)
			return wrapJSONP(callback, root, suffix);
		return root;
	} catch (e) {
		return errorPage(e, raw);
	}
}

function nested(val, level, nl) {
	if (null === val)
		return nullV();
	switch (typeof val) {
		case 'boolean': return boolV(val);
		case 'number': return numV(val);
		case 'string':
			return (/^(\w+):\/\/[^\s]+$/i.test(val)) ? linkV(val) : stringV(val);
		case 'object':
			return (Array.isArray(val))
				? array(val, level + 1, nl)
				: dict(val, level + 1, nl);
	}
	return '&lt;-unsupported-type-&gt;';
}

function dict(dict, level, nl) {
	let output = '';
	for (let key in dict) {
		if (output)
			output += indent(',<br>', level);
		output += propK(key) + ': ' + nested(dict[key], level, '<br>');
	}
	if (!output)
		return '{}';
	return '<span class="folder">{' + foldableContent(output, level, nl) + '}</span>';
}

function array(arr, level, nl) {
	let output = '';
	for (let i = 0; i < arr.length; i++) {
		if (i > 0)
			output += indent(',<br>', level);
		output += nested(arr[i], level, '<br>');
	}
	if (!output)
		return '[]';
	return '<span class="folder">[' + foldableContent(output, level, nl) + ']</span>';
}

// foldable content

function foldableContent(output, level, nl) {
	let collapsible = '<i onmouseover="highlight(this, true)" onmouseout="highlight(this, false)" onclick="fold(this)"></i>';
	return collapsible + '<span class="content">' + indent(nl, level) + output + indent('<br>', level - 1) + '</span>' + collapsible
}

function fold(sender) {
	let folder = sender.parentNode;
	folder.classList.toggle('closed');
}

function highlight(sender, show) {
	let folder = sender.parentNode;
	show ? folder.classList.add('highlight') : folder.classList.remove('highlight');
}
