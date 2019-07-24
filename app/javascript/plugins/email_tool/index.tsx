import { omit, pick } from 'lodash';
import * as React from 'react';
import { render } from 'react-dom';
import { Store } from 'redux';
import URI from 'urijs';
import ComponentWrapper from '../../components/ComponentWrapper';
import { IAppState } from '../../types';
import { camelizeKeys } from '../../util/util';
import Plugin from '../plugin';
import EmailToolView from './EmailToolView';

interface IEmailPensionOptions {
  el: HTMLElement;
  namespace: string;
  config: any; // todo
  store: Store<IAppState>;
}
export const init = options => {
  if (!options.el) {
    options.el = document.getElementById('email-tool-component');
  }
  const { el, store } = options;
  const member = window.champaign.personalization.member;
  const memberData = pick(member, 'name', 'email', 'country', 'postal');
  const trackingParams = pick(
    window.champaign.personalization.urlParams,
    'source',
    'akid',
    'referring_akid',
    'referrer_id',
    'rid'
  );
  const config = {
    ...options.config,
    ...memberData,
    ...trackingParams,
    onSuccess(target) {
      window.location.href = URI('{{ follow_up_url }}')
        .addSearch({
          'target[name]': target.name,
          'target[title]': target.title,
        })
        .toString();
    },
  };

  return new EmailPension({
    config,
    el,
    namespace: 'emailpension',
    store,
  });
};

class EmailPension extends Plugin<any> {
  public store: Store<IAppState>;
  public customRenderer: (instance: EmailPension) => any | undefined;
  public wrappedReactComponent?: React.Component;

  constructor(options: IEmailPensionOptions) {
    super(options);
    this.render();
  }

  public render() {
    if (this.customRenderer) {
      return this.customRenderer(this);
    }

    const props = omit(camelizeKeys(this.config), 'id', 'ref');

    return render(
      <ComponentWrapper store={this.store} locale={window.I18n.locale}>
        <EmailToolView {...props} />
      </ComponentWrapper>,
      this.el
    );
  }
}
