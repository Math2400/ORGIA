/**
 * Periods Manager Plugin - plugin.js
 * Timer interception, UI registration, and SP action forwarding.
 */

function dayIndex(d) {
  return (d.getDay() + 6) % 7;
}

function parseTime(str) {
  var parts = str.split(':');
  return parseInt(parts[0], 10) * 60 + parseInt(parts[1], 10);
}

async function loadData() {
  try {
    var raw = await PluginAPI.loadSyncedData();
    if (raw) return JSON.parse(raw);
  } catch (e) {
    // ignore
  }
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

PluginAPI.registerHeaderButton({
  label: 'Periods',
  icon: 'schedule',
  onClick: function () {
    PluginAPI.showIndexHtmlAsView();
  },
});

PluginAPI.registerShortcut({
  id: 'show_periods',
  label: 'Show Periods Manager',
  onExec: function () {
    PluginAPI.showIndexHtmlAsView();
  },
});

PluginAPI.registerHook(PluginAPI.Hooks.ACTION, async function (payload) {
  var iframes = document.querySelectorAll('iframe');
  iframes.forEach(function (iframe) {
    if (iframe.src && iframe.src.includes('periods-manager')) {
      iframe.contentWindow.postMessage({ type: 'SP_ACTION', action: payload.action }, '*');
    }
  });

  if (!payload || !payload.action) return;
  if (payload.action.type !== '[Task] Toggle start') return;

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
  } catch (e) {
    // Silently fail — don't break the timer
  }
});
