# frozen_string_literal: true

RSpec.describe TypesDeChamp::PrefillCommuneTypeDeChamp do
  let(:procedure) { create(:procedure) }
  let(:type_de_champ) { build(:type_de_champ_communes, procedure: procedure) }
  let(:memory_store) { ActiveSupport::Cache.lookup_store(:memory_store) }

  before do
    allow(Rails).to receive(:cache).and_return(memory_store)
    Rails.cache.clear
  end

  before do
    VCR.insert_cassette('api_geo_departements')
    VCR.insert_cassette('api_geo_communes')
  end

  after do
    VCR.eject_cassette('api_geo_departements')
    VCR.eject_cassette('api_geo_communes')
  end

  describe 'ancestors' do
    subject { described_class.new(type_de_champ, procedure.active_revision) }

    it { is_expected.to be_kind_of(TypesDeChamp::PrefillTypeDeChamp) }
  end

  describe '#all_possible_values' do
    let(:expected_values) do
      departements.map { |departement| "#{departement[:code]} (#{departement[:name]}) : https://geo.api.gouv.fr/communes?codeDepartement=#{departement[:code]}" }
    end
    subject(:all_possible_values) { described_class.new(type_de_champ, procedure.active_revision).all_possible_values }

    it { expect(all_possible_values).to match(expected_values) }
  end

  describe '#example_value' do
    let(:departement_code) { departements.pick(:code) }
    let(:commune_code) { APIGeoService.communes(departement_code).pick(:code) }
    subject(:example_value) { described_class.new(type_de_champ, procedure.active_revision).example_value }

    it { is_expected.to eq([departement_code, commune_code]) }
  end

  describe '#to_assignable_attributes' do
    let(:champ) { create(:champ_communes, type_de_champ: type_de_champ) }
    subject(:to_assignable_attributes) do
      described_class.build(type_de_champ, procedure.active_revision).to_assignable_attributes(champ, value)
    end

    context 'when the value is nil' do
      let(:value) { nil }
      it { is_expected.to match(nil) }
    end

    context 'when the value is empty' do
      let(:value) { '' }
      it { is_expected.to match(nil) }
    end

    context 'when the value is a string' do
      let(:value) { 'hello' }
      it { is_expected.to match(nil) }
    end

    context 'when the value is an array of one element' do
      context 'when the first element is a valid departement code' do
        let(:value) { ['01'] }
        it { is_expected.to match({ id: champ.id, code_departement: '01', departement: 'Ain' }) }
      end

      context 'when the first element is not a valid departement code' do
        let(:value) { ['totoro'] }
        it { is_expected.to match(nil) }
      end
    end

    context 'when the value is an array of two elements' do
      context 'when the first element is a valid departement code' do
        context 'when the second element is a valid insee code' do
          let(:value) { ['01', '01457'] }
          it { is_expected.to match({ id: champ.id, code_departement: '01', departement: 'Ain', external_id: '01457', value: 'Vonnas (01540)' }) }
        end

        context 'when the second element is not a valid insee code' do
          let(:value) { ['01', 'totoro'] }
          it { is_expected.to match(nil) }
        end
      end

      context 'when the first element is not a valid departement code' do
        let(:value) { ['totoro', '01457'] }
        it { is_expected.to match(nil) }
      end
    end

    context 'when the value is an array of three or more elements' do
      context 'when the first element is a valid departement code' do
        context 'when the second element is a valid insee code' do
          let(:value) { ['01', '01457', 'hello'] }
          it { is_expected.to match({ id: champ.id, code_departement: '01', departement: 'Ain', external_id: '01457', value: 'Vonnas (01540)' }) }
        end

        context 'when the second element is not a valid insee code' do
          let(:value) { ['01', 'totoro', 'hello'] }
          it { is_expected.to match(nil) }
        end
      end

      context 'when the first element is not a valid departement code' do
        let(:value) { ['totoro', '01457', 'hello'] }
        it { is_expected.to match(nil) }
      end
    end
  end

  private

  def departements
    APIGeoService.departements.sort_by { _1[:code] }
  end
end
