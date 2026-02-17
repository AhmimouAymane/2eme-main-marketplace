import React from 'react';

const ImageShow = (props) => {
    const { record, property } = props;
    const value = record.params[property.name];

    if (!value) {
        return <span>Pas d'image</span>;
    }

    return (
        <div style={{ marginBottom: '20px' }}>
            <label style={{ display: 'block', color: '#999', fontSize: '12px', marginBottom: '8px' }}>
                IMAGE DU PRODUIT
            </label>
            <img
                src={value}
                alt="Product"
                style={{
                    maxWidth: '100%',
                    maxHeight: '600px',
                    borderRadius: '8px',
                    border: '1px solid #eee'
                }}
            />
        </div>
    );
};

export default ImageShow;
