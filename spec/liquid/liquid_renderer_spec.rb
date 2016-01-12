require 'rails_helper'

describe LiquidRenderer do

  let!(:body_partial) { create :liquid_partial, title: 'body_text', content: '<p>{{ content }}</p>' }
  let(:liquid_layout) { create :liquid_layout, content: "<h1>{{ title }}</h1> {% include 'body_text' %}" }
  let(:page) { create :page, liquid_layout: liquid_layout, content: 'sliiiiide to the left' }
  let(:renderer) { LiquidRenderer.new(page) }

  describe 'new' do
    it 'receives the correct arguments' do
      expect{
        LiquidRenderer.new(page, layout: liquid_layout, location: {}, member: {}, url_params: {hi: 'a'})
      }.not_to raise_error
    end

    it 'requires only page' do
      expect{
        LiquidRenderer.new(page)
      }.not_to raise_error
    end

    it 'does not receive arbitrary keyword arguments' do
      expect{
        LiquidRenderer.new(page, secondary_layout: liquid_layout)
      }.to raise_error(ArgumentError)
    end

    describe 'setting locale' do

      after :each do
        I18n.locale = I18n.default_locale
      end

      describe "leaves english as the locale when page" do
        it 'has no language' do
          page.language = nil
          LiquidRenderer.new(page, layout: liquid_layout)
          expect(I18n.locale).to eq :en
          expect(I18n.t('common.save')).to eq 'Save'
        end

        it "has a nonsense language code" do
          page.language = build :language, code: 'xxx'
          LiquidRenderer.new(page, layout: liquid_layout)
          expect(I18n.locale).to eq :en
          expect(I18n.t('common.save')).to eq 'Save'
        end

        it "has an unsupported language code" do
          page.language = build :language, code: 'es'
          LiquidRenderer.new(page, layout: liquid_layout)
          expect(I18n.locale).to eq :en
          expect(I18n.t('common.save')).to eq 'Save'
        end
      end

      it "changes the locale when it's supported" do
        page.language = build :language, code: 'fr'
        LiquidRenderer.new(page, layout: liquid_layout)
        expect(I18n.locale).to eq :fr
        expect(I18n.t('common.save')).to eq 'Enregistrer'
      end
    end
  end

  describe "render" do
    it "returns an html string with the title" do
      expect(renderer.render).to include("<h1>#{page.title}</h1>")
    end

    it "renders the partial with the content" do
      expect(renderer.render).to include("<p>#{page.content}</p>")
    end

    describe 'handles a missing translation' do

      it 'by raising an error in test' do
        expect(Rails.env.test?).to eq true
        liquid_layout.update_attributes(content: "{{ 'fundraiser.lunacy' | t }}")
        expect{ renderer.render }.to raise_error I18n::TranslationMissing
      end

      it 'by raising an error in development' do
        allow(Rails).to receive(:env).and_return "development".inquiry
        expect(Rails.env.development?).to eq true
        liquid_layout.update_attributes(content: "{{ 'fundraiser.lunacy' | t }}")
        expect{ renderer.render }.to raise_error I18n::TranslationMissing
      end

      it 'by showing the best effort on production' do
        allow(Rails).to receive(:env).and_return "production".inquiry
        expect(Rails.env.production?).to eq true
        liquid_layout.update_attributes(content: "{{ 'fundraiser.lunacy' | t }}")
        expect{ renderer.render }.not_to raise_error
        expect( renderer.render ).to include('lunacy');
      end
    end

    it 'fills in localized string' do
      liquid_layout.update_attributes(content: "{{ 'common.confirm' | t }}")
      expect(renderer.render).to eq "Are you sure?"
    end

  end

  describe "default_markup" do
    it "reads a real file containing a title tag" do
      expect(renderer.default_markup).to include ("title")
    end

    it "reads a real file of reasonable length" do
      expect(renderer.default_markup.length).to be > 20
    end
  end

  describe "data" do
    it "should have string keys" do
      expect(renderer.data.keys.map(&:class).uniq).to eq [String]
    end

    it "should have expected keys" do
      expected_keys = ['plugins', 'ref', 'images', 'shares', 'country_option_tags',
                      'url_params', 'primary_image', 'follow_up_url', 'outstanding_fields',
                      'petition_target', 'location', 'member']
      expected_keys += page.liquid_data.keys.map(&:to_s)
      actual_keys = renderer.data.keys
      expect(actual_keys).to match_array(expected_keys)
    end

    describe 'outstanding_fields' do
      it 'is [] if it has no plugins' do
        expect(page.plugins.size).to eq 0
        expect(LiquidRenderer.new(page).data['outstanding_fields']).to eq []
      end

      it "is [] if it's plugins don't have forms" do
        create :plugins_thermometer, page: page
        expect(LiquidRenderer.new(page).data['outstanding_fields']).to eq []
      end

      it 'has the fields from one plugin form' do
        form = create :form_with_email_and_name
        create :plugins_fundraiser, page: page, form: form
        expect(LiquidRenderer.new(page).data['outstanding_fields']).to eq ['email', 'name']
      end

      it 'has from both plugin forms' do
        p1 = create :plugins_fundraiser, page: page
        p2 = create :plugins_petition, page: page
        p1.update_attributes(form: create(:form_with_email_and_name))
        p2.update_attributes(form: create(:form_with_phone_and_country))
        expect(LiquidRenderer.new(page).data['outstanding_fields']).to match_array ['email', 'name', 'phone', 'country']
      end
    end

    describe 'location' do

      let(:location) { instance_double('Geocoder::Result::Freegeoip', data: {country_code: 'US'}, country_code: 'US') }

      before :each do
        allow(Donations::Utils).to receive(:currency_from_country_code){ 'USD' }
      end

      it 'returns the location its passed' do
        allow(location).to receive(:data){ {region: 'USA' } }
        allow(location).to receive(:country_code){ nil }
        renderer = LiquidRenderer.new(page, location: location)
        expect(renderer.data['location']).to eq location.data.stringify_keys
        expect(Donations::Utils).not_to have_received(:currency_from_country_code).with('DE')
      end

      it 'calls currency_from_country_code with member country' do
        member = build :member, country: 'DE'
        allow(location).to receive(:country_code){ 'GB' }
        allow(location).to receive(:data){ {country_code: 'GB' } }
        renderer = LiquidRenderer.new(page, member: member, location: location)
        expect(renderer.data['location']).to eq({'country_code' => 'GB', 'currency' => 'USD'})
        expect(Donations::Utils).to have_received(:currency_from_country_code).with('DE')
      end

      it 'calls currency_from_country_code with location country if member has none' do
        member = build :member, country: nil
        allow(location).to receive(:country_code){ 'GB' }
        allow(location).to receive(:data){ {country_code: 'GB' } }
        renderer = LiquidRenderer.new(page, member: member, location: location)
        expect(renderer.data['location']).to eq({'country_code' => 'GB', 'currency' => 'USD'})
        expect(Donations::Utils).to have_received(:currency_from_country_code).with('GB')
      end
    end

    describe 'member' do
      it 'gives email as welcome name if no name' do
        member = build :member, first_name: nil, last_name: "", email: 'sup@dude.com'
        renderer = LiquidRenderer.new(page, member: member)
        expect(renderer.data['member']['welcome_name']).to eq 'sup@dude.com'
      end

      it 'gives first name and last name if available' do
        member = build :member, first_name: 'big', last_name: "dog", email: 'sup@dude.com'
        renderer = LiquidRenderer.new(page, member: member)
        expect(renderer.data['member']['welcome_name']).to eq 'big dog'
      end
    end

  end

end
