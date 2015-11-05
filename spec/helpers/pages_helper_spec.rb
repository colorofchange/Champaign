require 'rails_helper'

describe PagesHelper do
  describe "#page_nav_item" do
    it "returns li element with link" do
      actual = helper.page_nav_item('foo', '/bar')
      expect(actual).to eq("<li><a href=\"/bar\">foo</a></li>")
    end
  end

  describe "#toggle_switch" do
    it "returns link when active" do
      actual = helper.toggle_switch(true, true, 'foo')
      expect(actual).to eq(
        "<a class=\"btn-primary btn toggle-button btn-default\" data-state=\"true\">foo</a>"
      )
    end

    it "returns link when inactive" do
      actual = helper.toggle_switch(true, false, 'foo')
      expect(actual).to eq(
        "<a class=\" btn toggle-button btn-default\" data-state=\"true\">foo</a>"
      )
    end
  end

  describe '#prefill_link' do
    it 'prefills link for twitter' do
      variant = Share::Twitter.new
      expect(variant.description).to eq nil
      expect(prefill_link(variant).description).to eq '{LINK}'
    end

    it 'prefills link for twitter' do
      variant = Share::Email.new
      expect(variant.body).to eq nil
      expect(prefill_link(variant).body).to eq '{LINK}'
    end

    it 'prefills nothing for facebook' do
      variant = Share::Facebook.new
      expect(prefill_link(variant).attributes).to eq Share::Facebook.new.attributes
    end
  end
end
