+++
title = "Predicting survival times for neuroblastoma patients using RNA-seq expression profiles"
date = 2018-05-30T00:00:00
draft = false

# Authors. Comma separated list, e.g. `["Tyler Grimes", "Alejandro R. Walker", "Susmita Datta", "Somnath Datta"]`.
authors = ["Tyler Grimes", "Alejandro R. Walker", "Susmita Datta", "Somnath Datta"]

# Publication type.
# Legend:
# 0 = Uncategorized
# 1 = Conference paper
# 2 = Journal article
# 3 = Manuscript
# 4 = Report
# 5 = Book
# 6 = Book section
publication_types = ["2"]

# Publication name and optional abbreviated version.
publication = "Biology Direct"

# Abstract and optional shortened version.
abstract = "**Background:** Neuroblastoma is the most common tumor of early childhood and is notorious for its high variability in clinical presentation. Accurate prognosis has remained a challenge for many patients. In this study, expression profiles from RNA-sequencing are used to predict survival times directly. Several models are investigated using various annotation levels of expression profiles (genes, transcripts, and introns), and an ensemble predictor is proposed as a heuristic for combining these different profiles. **Results:** The use of RNA-seq data is shown to improve accuracy in comparison to using clinical data alone for predicting overall survival times. Furthermore, clinically high-risk patients can be subclassified based on their predicted overall survival times. In this effort, the best performing model was the elastic net using both transcripts and introns together. This model separated patients into two groups with 2-year overall survival rates of 0.40±0.11 (n=22) versus 0.80±0.05 (n=68). The ensemble approach gave similar results, with groups 0.42±0.10 (n=25) versus 0.82±0.05 (n=65). This suggests that the ensemble is able to effectively combine the individual RNA-seq datasets. \n **Conclusions:** Using predicted survival times based on RNA-seq data can provide improved prognosis by subclassifying clinically high-risk neuroblastoma patients."
abstract_short = "In this study, expression profiles from RNA-sequencing of Neuroblastoma tumor samples are used to predict patient survival times. Several models are investigated using various annotation levels of expression profiles (genes, transcripts, and introns), and an ensemble predictor is proposed as a heuristic for combining these different profiles. The use of RNA-seq data is shown to improve accuracy in comparison to using clinical data alone for predicting overall survival times."

# Is this a featured publication? (true/false)
featured = true

# Projects (optional).
#   Associate this publication with one or more of your projects.
#   Simply enter your project's folder or file name without extension.
#   E.g. `projects = ["deep-learning"]` references 
#   `content/project/deep-learning/index.md`.
#   Otherwise, set `projects = []`.
projects = ["CAMDA-2017"]

# Tags (optional).
#   Set `tags = []` for no tags, or use the form `tags = ["A Tag", "Another Tag"]` for one or more tags.
tags = ["Survival analysis", "RNA-seq", "Sparse estimation"]

# Links (optional).
url_source = "https://biologydirect.biomedcentral.com/articles/10.1186/s13062-018-0213-x"
url_code = "https://github.com/tgrimes/CAMDA-2017-Neuroblastoma"
url_slides = "https://tgrimes.github.io/files/presentations/CAMDA_presentation.pptx"


# Custom links (optional).
#   Uncomment line below to enable. For multiple links, use the form `[{...}, {...}, {...}]`.
# url_custom = [{name = "Custom Link", url = "http://example.org"}]

# Digital Object Identifier (DOI)
doi = ""

# Does this page contain LaTeX math? (true/false)
math = true

# Featured image
# To use, add an image named `featured.jpg/png` to your page's folder. 
[image]
  # Caption (optional)
  caption = "Image credit: [**Unsplash**](https://unsplash.com/photos/pLCdAaMFLTE)"

  # Focal point (optional)
  # Options: Smart, Center, TopLeft, Top, TopRight, Left, Right, BottomLeft, Bottom, BottomRight
  focal_point = ""
+++

More detail can easily be written here using *Markdown* and $\rm \LaTeX$ math code.
