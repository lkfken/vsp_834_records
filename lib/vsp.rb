require_relative 'vsp/filename'

module VSP
  MEDIA_ID = '4204657'

  ADULT_RIDER_DIVISION = {:plana => '300433990003', :planb => '300433990004', :planc => '300433990005'} # IFP is Plan A, ESP is Plan C
  OFF_EXCHANGE_PEDIATRIC_DIVISION = {ifp: 'OFF0001', esp: 'OFF0002'}
  ON_EXCHANGE_PEDIATRIC_DIVISION = {ifp: 'ON0001', esp: 'ON0002'}
  SENIOR_DIVISION = {regular: '300276020002', select: '300276020001'}

  def current_month
    @current_month ||= begin
                         date = Date.today.next_month
                         Date.civil(date.year, date.month, 1)
                       end
  end

  module_function :current_month
end