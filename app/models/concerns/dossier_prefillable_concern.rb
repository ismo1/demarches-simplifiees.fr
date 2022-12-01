# frozen_string_literal: true

module DossierPrefillableConcern
  extend ActiveSupport::Concern

  def prefill!(champs_public_attributes)
    return unless champs_public_attributes.any?

    assign_attributes(champs_public_attributes: champs_public_attributes.map { |h| h.merge(prefilled: true) })
    save(validate: false)
  end
end
