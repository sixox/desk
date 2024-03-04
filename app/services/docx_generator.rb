require 'docx'
require 'numbers_and_words'

class DocxGenerator
  # Generates the DOCX document from a template
  def self.generate_from_template(template_path, model_object, output_path)
    doc = Docx::Document.open(template_path)

    data = prepare_data_for_model(model_object)

    # Replace placeholders in the document
    replace_placeholders(doc, data)

    doc.save(output_path)
  end

  private

  # Replaces placeholders throughout the document
  def self.replace_placeholders(doc, data)
    # Iterate through each paragraph in the document
    doc.paragraphs.each do |paragraph|
      replace_paragraph_text(paragraph, data)
    end

    # Iterate through each table and cell in the document
    doc.tables.each do |table|
      table.rows.each do |row|
        row.cells.each do |cell|
          cell.paragraphs.each do |paragraph|
            replace_paragraph_text(paragraph, data)
          end
        end
      end
    end
  end

  # Replaces text in a given paragraph based on the data hash
  def self.replace_paragraph_text(paragraph, data)
    data.each do |placeholder, value|
      if paragraph.text.include?("{#{placeholder}}")
        new_text = value.is_a?(Array) ? value.join("\n") : value.to_s
        paragraph.each_text_run do |text_run|
          text_run.text = text_run.text.gsub("{#{placeholder}}", new_text)
        end
      end
    end
  end

  def self.prepare_data_for_model(model_object)
    # Your existing implementation to prepare data
    data = {}
    if model_object.is_a?(Pi)
      data = {
        "PI_NUMBER" => model_object.number,
        "PI_SELLER" => model_object.seller.upcase,
        "PI_BUYER" => model_object.customer.name,
        "BUYER_COMPANY" => model_object.customer.company.upcase,
        "DATE" => model_object.created_at.strftime('%d %b %Y'),
        "VALIDITY" => model_object.validity.to_i,
        "PRODUCT" => model_object.product.upcase,
        "QUANTITY" => model_object.quantity.to_i,
        "UNIT_PRICE" => model_object.unit_price.to_i,
        "TOTAL_PRICE" => model_object.total_price.to_i,
        "TOTAL_PRICE_IN_WORDS" => model_object.total_price.to_i.to_words.upcase,
        "DELIVERY_TIME" => model_object.delivery_time.to_i,
        "ADVANCE" => model_object.payment_term,
        "PACKING" => model_object.packing_type.upcase,
        "POL" => model_object.pol.upcase,
        "POD" => model_object.pod.upcase,
        "TOLERANCE" => model_object.tolerance,
        "SHORT_CURRENCY" => model_object.currency == "dollar" ? "USD" : "AED",
        "CURRENCY" => model_object.currency.upcase,
        "TERM" => model_object.incoterm.upcase,
        "ACCOUNT" => model_object.account.details.split("\n") # Handle new lines
      }
    elsif model_object.is_a?(Ci)
      data = {
        "CI_NUMBER" => model_object.number,
        "CI_SELLER" => model_object.pi.seller.upcase,
        "CI_BUYER" => model_object.pi.customer.name,
        "BUYER_COMPANY" => model_object.pi.customer.company.upcase,
        "POL" => model_object.pi.pol.upcase,
        "POD" => model_object.pi.pod.upcase,
        "PI_NUMBER" => model_object.pi.number,
        "PI_DATE" => model_object.pi.created_at.strftime('%d %b %Y'),
        "DATE" => model_object.created_at.strftime('%d %b %Y'),
        "PRODUCT" => model_object.pi.product.upcase,
        "COUNT" => model_object.pi.packing_count,
        "PACKING" => model_object.pi.packing_type.upcase,
        "NET" => model_object.net_weight,
        "GROSS" => model_object.gross_weight,
        "UNIT_PRICE" => model_object.pi.unit_price.to_i,
        "SHORT_CURRENCY" => model_object.pi.currency == "dollar" ? "USD" : "AED",
        "TERM" => model_object.pi.incoterm.upcase,
        "TOTAL_PRICE" => model_object.total_price.to_i,
        "ADVANCE" => model_object.advance_payment.to_i,
        "BALANCE" => model_object.balance_payment.to_i,
        "TOTAL_PRICE_IN_WORDS" => model_object.total_price.to_i.to_words.upcase,
        "CURRENCY" => model_object.pi.currency.upcase,
        "ACCOUNT" => model_object.account.details.split("\n") # Handle new lines


      }
    end
    data
  end
end
