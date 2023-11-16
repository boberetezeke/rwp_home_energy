require_relative '../../../ruby_world_prototype/app/objects/obj'
require_relative '../../../ruby_world_prototype/app/objects/database'
require_relative '../../../ruby_world_prototype/app/objects/store'
require_relative '../../app/objects/brultech_reading'
require_relative '../../app/objects/power_circuit'
require_relative '../../app/objects/brultech_store'

describe Obj::BrultechStore do
  describe '#sync' do
    let(:db) { Obj::Database.new }
    subject { Obj::BrultechStore.new(db, 'spec/fixtures/brultech')}

    before do
      allow(subject).to receive(:update_readings)
      subject.sync
    end

    it 'builds readings objects' do
      expect(db.objs[:brultech_reading].size).to eq(62)
    end

    it 'builds power circuits' do
      expect(db.objs[:power_circuit].size).to eq(31)
    end

    it 'has two readings per power circuit' do
      power_circuits = db.objs[:power_circuit].values
      num_uniq_readings = power_circuits.map{|pc| pc.brultech_readings.size}.uniq
      expect(num_uniq_readings).to eq([2])
    end
  end
end