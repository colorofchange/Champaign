// @flow
import React from 'react';
import { render } from 'react-dom';
import { Plugin } from '../index';
import { PetitionComponent } from './PetitionComponent';
import ComponentWrapper from '../../components/ComponentWrapper';
import { resetMember } from '../../state/member/reducer';
import type { Store } from 'redux';
import type { AppState } from '../../state';

import './petition.css';

export const init = (options: any) => {
  return new Petition({
    el: options.el,
    namespace: 'petition',
    config: options.config,
    store: options.store,
  });
};

type PetitionOptions = {
  el: HTMLElement,
  config: any, // todo
  store: Store<AppState, *>,
};

export class Petition extends Plugin {
  store: Store<AppState, *>;

  constructor(options: PetitionOptions) {
    super(options);
    this.store = options.store;
    this.render();
  }

  updateForm(fieldName: string, value: string) {
    console.info('Petition#updateForm not implemented');

    this.render();
  }

  resetMember = () => this.store.dispatch(resetMember());

  submit = () => {
    console.info('Petition#submit not implemented');
  };

  render() {
    const el = this.el;
    if (el) {
      render(
        <ComponentWrapper locale={I18n.locale} store={champaign.store}>
          <PetitionComponent config={this.config} />
        </ComponentWrapper>,
        el
      );
    }
  }
}