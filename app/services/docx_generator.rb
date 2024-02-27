require 'docx'
require 'numbers_and_words'


class DocxGenerator
  def self.generate_from_template(template_path, model_object, output_path)
    doc = Docx::Document.open(template_path)

    # Determine the type of the model_object (PI or CI) and prepare data accordingly
    data = prepare_data_for_model(model_object)

    # Replace placeholders in paragraphs
    replace_placeholders_in_paragraphs(doc, data)

    # Replace placeholders in tables
    replace_placeholders_in_tables(doc, data)

    # Save the modified document
    doc.save(output_path)
  end

  private

  def self.replace_placeholders_in_paragraphs(doc, data)
    doc.paragraphs.each do |p|
      data.each do |placeholder, value|
        if p.text.include?("{#{placeholder}}")
          p.each_text_run do |tr|
            tr.text = tr.text.gsub("{#{placeholder}}", value.to_s)
          end
        end
      end
    end
  end

  def self.replace_placeholders_in_tables(doc, data)
    doc.tables.each do |table|
      table.rows.each do |row|
        row.cells.each do |cell|
          data.each do |placeholder, value|
            if cell.text.include?("{#{placeholder}}")
              cell.paragraphs.each do |paragraph|
                paragraph.each_text_run do |text_run|
                  text_run.text = text_run.text.gsub("{#{placeholder}}", value.to_s)
                end
              end
            end
          end
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
        "TERM" => model_object.incoterm.upcase




      }
    elsif model_object.is_a?(Ci)
      data = {
        "CI_NUMBER" => model_object.number,
        "PROJECT_NUMBER" => model_object.project.number,
        "DESCRIPTION" => model_object.created_at.strftime('%Y-%m-%d')
      }
    end
    data
  end
end
