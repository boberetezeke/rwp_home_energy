class Obj::PowerCircuit < Obj
  has_many :brultech_readings, :brultech_reading, :power_circuit_id, inverse_of: :power_circuit

  def self.default_display
    {
      sym_sets: {
        default: [:id,
                  :name
        ]
      },
      fields: {
        id: { width: 35, type: :string, title: 'ID' },
        name: { width: 20, type: :string, title: 'Name' }
      }
    }
  end

  def initialize(name)
    super(:power_circuit, {
      name: name
    })
  end
end
