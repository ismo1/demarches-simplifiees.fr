FactoryBot.define do
  factory :individual do
    gender { 'Monsieur' }
    nom { 'Julien' }
    prenom { 'Xavier' }
    birthdate { Date.new(1991, 11, 01) }
    association :dossier
  end
end
