import { logEvent } from '../util/log_event';

const blacklist = ['update_form'];

const blacklisted = event => blacklist.indexOf(event) > -1;

const passToLogTracker = () => next => action => {
  const { type, skip_log = false, ...rest } = action;

  if (!skip_log && !blacklisted(type)) {
    logEvent(type, rest);
  }

  return next(action);
};

export default passToLogTracker;
