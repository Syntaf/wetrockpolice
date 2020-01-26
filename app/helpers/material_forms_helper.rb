module MaterialFormsHelper
    class MaterialFormBuilder < ActionView::Helpers::FormBuilder
        def validation_message(attribute)
            @template.content_tag(:div, '', { class: 'invalid-feedback',  data: { :invalid_feedback => attribute }})
        end

        def text_field(attribute, options={})
            options = self.append_material_class(options)
            super
        end

        def email_field(attribute, options={})
            options = self.append_material_class(options)
            super
        end

        def telephone_field(attribute, options={})
            options = self.append_material_class(options)
            super
        end

        def number_field(attribute, options={})
            options = self.append_material_class(options)
            super
        end

        def select(attribute, choices=nil, options={}, html_options={}, &block)
            html_options = self.append_material_class(html_options)
            super
        end

        def submit(value=nil, options={})
            options = self.append_material_class(options, "btn btn-primary")
            super
        end

        def append_material_class(options={}, html_class="form-control")
            if options.key?(:class)
                options[:class] << " " << html_class
            else
                options[:class] = html_class
            end

            options
        end
    end
end
