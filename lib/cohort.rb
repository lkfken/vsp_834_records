require_relative 'cohort/pediatric'
require_relative 'cohort/adult_rider'
require_relative 'cohort/senior'

module Cohort
  def dataset
    pediatric = Cohort::Pediatric.new(current_month: VSP.current_month)
    adult_rider = Cohort::AdultRider.new(current_month: VSP.current_month)
    senior = Cohort::Senior.new(current_month: VSP.current_month)

    datasets = [adult_rider, pediatric, senior].map do |o|
      o.dataset.select(:membernumber, :groupnumber, :groupname, :planname, :group_region, :effectivedate, :expirationdate,
                       :dateofbirth, :age, :lastname, :firstname, :gender, :address1, :address2, :city, :state, :zip,
                       :lineofbusiness, :productline, :contract_date, :riskgroupnumber, :vsp_division, :file_id)
    end

    # VSP can only accept 1 record per member. If a member has multiple records (coverages), keep only one (rnk = 1).
    datasets[0].union(datasets[1]).union(datasets[2]).from_self
        .select_append { rank.function.over(:partition => :membernumber,
                                            order: Sequel.desc(:expirationdate)).as(:rnk) }.from_self
        .where(:rnk => 1)
  end

  module_function :dataset
end