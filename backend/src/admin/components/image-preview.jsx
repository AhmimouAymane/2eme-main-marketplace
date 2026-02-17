import React from 'react';

const ImagePreview = (props) => {
    const { record, property } = props;
    const value = record.params[property.name];

    if (!value) {
        return null;
    }

    return (
        <div style={{ padding: '4px' }}>
            <img
                src={value}
                alt="Aperçu"
                style={{
                    maxWidth: '80px',
                    maxHeight: '80px',
                    borderRadius: '4px',
                    objectFit: 'cover'
                }}
            />
        </div>
    );
};

export default ImagePreview;
