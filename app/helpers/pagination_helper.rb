module PaginationHelper
  def pagination_frame_tag(namespace, page, data: {}, **attributes, &)
    turbo_frame_tag pagination_frame_id_for(namespace, page.number), data: data, role: "presentation", **attributes, &
  end

  def link_to_next_page(namespace, page, label: "Load more", data: {}, **attributes)
    return unless page.before_last?

    pagination_link(namespace, page.number + 1, label: label, data: data, **attributes)
  end

  def pagination_link(namespace, page_number, label: "Load more", url_params: {}, data: {}, **attributes)
    link_to label, url_for(request.query_parameters.merge(page: page_number, **url_params)),
      "aria-label": "Load page #{page_number}",
      id: "#{namespace}-pagination-link-#{page_number}",
      class: class_names(attributes.delete(:class), "pagination-link"),
      data: {
        turbo_frame: pagination_frame_id_for(namespace, page_number),
        pagination_target: "paginationLink",
        action: "click->pagination#loadPage:prevent",
        **data
      },
      **attributes
  end

  def pagination_frame_id_for(namespace, page_number)
    "#{namespace}-pagination-contents-#{page_number}"
  end

  def with_manual_pagination(name, page, **properties, &block)
    pagination_list name, **properties do
      concat(pagination_frame_tag(name, page) do
        concat capture(&block)
        concat link_to_next_page(name, page)
      end)
    end
  end

  private
    def pagination_list(name, tag_element: :div, **properties, &block)
      classes = properties.delete(:class)
      properties[:id] ||= "#{name}-pagination-list"
      tag.public_send tag_element,
        class: class_names(name, classes),
        data: { controller: "pagination" },
        **properties,
        &block
    end
end
