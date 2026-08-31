/**
 * Période + Chrono — host bridge
 * Forwards SP actions into the iframe and keeps Periods timer interception.
 */

function dayIndex(d) {
  return (d.getDay() + 6) % 7;
}

function parseTime(str) {
  var parts = str.split(':');
  return parseInt(parts[0], 10) * 60 + parseInt(parts[1], 10);
}

function unwrapPeriods(parsed) {
  if (!parsed) return { timetables: {}, dailyOverrides: {}, activeTimetableId: null, syncLog: [] };
  if (parsed._unified) parsed = parsed.periods || {};
  return parsed;
}

async function loadData() {
  try {
    var raw = await PluginAPI.loadSyncedData();
    if (raw) {
      var parsed = typeof raw === 'string' ? JSON.parse(raw) : raw;
      return unwrapPeriods(parsed);
    }
  } catch (e) {}
  return { timetables: {}, dailyOverrides: {}, activeTimetableId: null, syncLog: [] };
}

function getEffectivePeriods(data, now) {
  var dateStr =
    now.getFullYear() +
    '-' +
    String(now.getMonth() + 1).padStart(2, '0') +
    '-' +
    String(now.getDate()).padStart(2, '0');

  if (data.dailyOverrides && data.dailyOverrides[dateStr]) {
    return data.dailyOverrides[dateStr].periods || [];
  }

  if (data.activeTimetableId && data.timetables && data.timetables[data.activeTimetableId]) {
    var tt = data.timetables[data.activeTimetableId];
    var dow = dayIndex(now);
    if (tt.days && tt.days[dow]) {
      return tt.days[dow].periods || [];
    }
  }

  return [];
}

function findCurrentPeriod(periods, now) {
  var mins = now.getHours() * 60 + now.getMinutes();
  for (var i = 0; i < periods.length; i++) {
    var p = periods[i];
    var start = parseTime(p.startTime);
    var end = parseTime(p.endTime);
    if (mins >= start && mins < end) return p;
  }
  return null;
}

function postToIframe(payload) {
  var iframes = document.querySelectorAll('iframe');
  iframes.forEach(function (iframe) {
    var src = iframe.getAttribute('src') || '';
    if (
      src.indexOf('periode-chrono') !== -1 ||
      src.indexOf('periods-manager') !== -1 ||
      src.indexOf('chrono') !== -1 ||
      src.indexOf('blob:') === 0 ||
      iframe.hasAttribute('srcdoc')
    ) {
      try {
        iframe.contentWindow.postMessage(payload, '*');
      } catch (e) {}
    }
  });
}

var lastCurrentTaskId = null;

PluginAPI.registerHeaderButton({
  label: 'Période',
  icon: 'schedule',
  onClick: function () {
    PluginAPI.showIndexHtmlAsView();
  },
});

PluginAPI.registerShortcut({
  id: 'show_periode_chrono',
  label: 'Show Période / Chrono',
  onExec: function () {
    PluginAPI.showIndexHtmlAsView();
  },
});

PluginAPI.registerHook(PluginAPI.Hooks.CURRENT_TASK_CHANGE, function (payload) {
  var task = payload && (payload.current || payload.task || payload);
  lastCurrentTaskId = task && task.id ? task.id : null;
  postToIframe({ type: 'SP_CURRENT_TASK', task: lastCurrentTaskId ? { id: lastCurrentTaskId } : null });
});

PluginAPI.registerHook(PluginAPI.Hooks.ACTION, async function (payload) {
  var action = payload && payload.action ? payload.action : payload;
  postToIframe({ type: 'SP_ACTION', action: action });

  if (!action || action.type !== '[Task] Toggle start') return;
  if (lastCurrentTaskId) return;

  try {
    var data = await loadData();
    var now = new Date();
    var periods = getEffectivePeriods(data, now);
    var currentPeriod = findCurrentPeriod(periods, now);

    if (!currentPeriod || !currentPeriod.taskIds || currentPeriod.taskIds.length === 0) {
      return;
    }

    var allTasks = await PluginAPI.getTasks();
    var tasksMap = {};
    for (var i = 0; i < allTasks.length; i++) {
      tasksMap[allTasks[i].id] = allTasks[i];
    }

    var targetTaskId = null;
    for (var j = 0; j < currentPeriod.taskIds.length; j++) {
      var tid = currentPeriod.taskIds[j];
      if (String(tid).indexOf('custom_') === 0) continue;
      var t = tasksMap[tid];
      if (t && !t.isDone) {
        targetTaskId = tid;
        break;
      }
    }

    if (targetTaskId) {
      PluginAPI.dispatchAction({
        type: '[Task] SetCurrentTask',
        id: targetTaskId,
      });
    }
  } catch (e) {}
});
