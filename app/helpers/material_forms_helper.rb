module MaterialFormsHelper
    class MaterialFormBuilder < ActionView::Helpers::FormBuilder
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

        def append_material_class(options={})
            if options.key?(:class)
                options[:class] << " form-control"
            else
                options[:class] = "form-control"
            end

            options
        end
    end
end
