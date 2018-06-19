import { configure } from 'enzyme';
import Adapter from 'enzyme-adapter-react-16';

require('dotenv').config({ path: 'env.yml' });
require('../../app/javascript/packs/globals');

configure({ adapter: new Adapter() });
