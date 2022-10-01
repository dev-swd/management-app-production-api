module Common
  extend ActiveSupport::Concern

  included do
    logger.info("Common module included!")
  end

  def getTime(h,m)
    hm = format("%02<number>d", number: h.to_i) + format("%02<number>d", number: m.to_i)
    if hm <= "2400" then
      retTime= Time.local(2022,1,1,h.to_i,m.to_i,00)
    else
      retTime= Time.local(2022,1,2,h.to_i,m.to_i,00)
    end
    return retTime
  end
end