class RemoveOldPermittedDomains < ActiveRecord::Migration
  def up
    moj_domains = %w(
      cjs.gsi.gov.uk
      digital.justice.gov.uk
      hmcourts-service.gsi.gov.uk
      hmcts.gsi.gov.uk
      hmps.gsi.gov.uk
      homeoffice.gsi.gov.uk
      ips.gsi.gov.uk
      justice.gsi.gov.uk
      legalaid.gsi.gov.uk
      noms.gsi.gov.uk
      publicguardian.gsi.gov.uk
      yjb.gsi.gov.uk
    )
    PermittedDomain.delete_all(domain: moj_domains)
  end
end
